# frozen_string_literal: true

module Ci
  class Bridge < Ci::Processable
    include Ci::Contextable
    include Ci::Deployable
    include Importable
    include AfterCommitQueue
    include Ci::HasRef

    InvalidBridgeTypeError = Class.new(StandardError)
    InvalidTransitionError = Class.new(StandardError)

    FORWARD_DEFAULTS = {
      yaml_variables: true,
      pipeline_variables: false
    }.freeze

    self.allow_legacy_sti_class = true

    belongs_to :project

    has_one :downstream_pipeline, through: :sourced_pipeline, source: :pipeline

    validates :ref, presence: true

    # rubocop:disable Cop/ActiveRecordSerialize
    serialize :options
    serialize :yaml_variables, ::Gitlab::Serializer::Ci::Variables
    # rubocop:enable Cop/ActiveRecordSerialize

    state_machine :status do
      after_transition [:created, :manual, :waiting_for_resource] => :pending do |bridge|
        bridge.run_after_commit do
          Ci::TriggerDownstreamPipelineService.new(bridge).execute # rubocop: disable CodeReuse/ServiceClass
        end
      end

      event :pending do
        transition all => :pending
      end

      event :manual do
        transition all => :manual
      end

      event :scheduled do
        transition all => :scheduled
      end

      event :actionize do
        transition created: :manual
      end

      event :start_cancel do
        transition CANCELABLE_STATUSES.map(&:to_sym) + [:manual] => :canceling
      end

      event :finish_cancel do
        transition CANCELABLE_STATUSES.map(&:to_sym) + [:manual, :canceling] => :canceled
      end

      event :inherit_success do
        transition all => :success
      end

      event :inherit_finish_cancel do
        transition all => :canceled
      end

      event :inherit_failed do
        transition all => :failed
      end
    end

    def retryable?
      return false if failed? && (pipeline_loop_detected? || reached_max_descendant_pipelines_depth?)

      super
    end

    def self.with_preloads
      preload(
        :metadata,
        user: [:followers, :followees],
        downstream_pipeline: [project: [:route, { namespace: :route }]],
        project: [:namespace]
      )
    end

    def self.clone_accessors
      %i[pipeline project ref tag options name
        allow_failure stage_idx
        yaml_variables when environment description needs_attributes
        scheduling_type ci_stage partition_id].freeze
    end

    def inherit_status_from_downstream!(pipeline)
      case pipeline.status
      when 'success'
        inherit_success!
      when 'canceled'
        inherit_finish_cancel!
      when 'failed', 'skipped'
        inherit_failed!
      else
        false
      end
    end

    def has_downstream_pipeline?
      sourced_pipeline.present?
    end

    def downstream_pipeline_params
      return child_params if triggers_child_pipeline?
      return cross_project_params if downstream_project.present?

      {}
    end

    def downstream_project
      strong_memoize(:downstream_project) do
        if downstream_project_path
          ::Project.find_by_full_path(downstream_project_path)
        elsif triggers_child_pipeline?
          project
        end
      end
    end

    def downstream_project_path
      strong_memoize(:downstream_project_path) do
        project = options&.dig(:trigger, :project)
        next unless project

        scoped_variables.to_hash_variables.then do |all_variables|
          ::ExpandVariables.expand(project, all_variables)
        end
      end
    end

    def parent_pipeline
      pipeline if triggers_child_pipeline?
    end

    def triggers_downstream_pipeline?
      triggers_child_pipeline? || triggers_cross_project_pipeline?
    end

    def triggers_child_pipeline?
      yaml_for_downstream.present?
    end

    def triggers_cross_project_pipeline?
      downstream_project_path.present?
    end

    def tags
      [:bridge]
    end

    def detailed_status(current_user)
      Gitlab::Ci::Status::Bridge::Factory
        .new(self, current_user)
        .fabricate!
    end

    def schedulable?
      false
    end

    def playable?
      action? && !archived? && manual?
    end

    def action?
      %w[manual].include?(self.when)
    end

    def can_auto_cancel_pipeline_on_job_failure?
      true
    end

    # rubocop: disable CodeReuse/ServiceClass
    # We don't need it but we are taking `job_variables_attributes` parameter
    # to make it consistent with `Ci::Build#play` method.
    def play(current_user, job_variables_attributes = nil)
      Ci::PlayBridgeService
        .new(project, current_user)
        .execute(self)
    end
    # rubocop: enable CodeReuse/ServiceClass

    def job_artifacts
      Ci::JobArtifact.none
    end

    def artifacts_expire_at; end

    def runner; end

    def tag_list
      Gitlab::Ci::Tags::TagList.new
    end

    def artifacts?
      false
    end

    def runnable?
      false
    end

    def any_unmet_prerequisites?
      false
    end

    def execute_hooks
      raise NotImplementedError
    end

    def to_partial_path
      'projects/generic_commit_statuses/generic_commit_status'
    end

    def yaml_for_downstream
      strong_memoize(:yaml_for_downstream) do
        includes = options&.dig(:trigger, :include)
        YAML.dump('include' => includes) if includes
      end
    end

    def target_ref
      branch = options&.dig(:trigger, :branch)
      return unless branch

      scoped_variables.to_hash_variables.then do |all_variables|
        ::ExpandVariables.expand(branch, all_variables)
      end
    end

    def dependent?
      strong_memoize(:dependent) do
        options&.dig(:trigger, :strategy) == 'depend'
      end
    end

    def target_revision_ref
      downstream_pipeline_params.dig(:target_revision, :ref)
    end

    def downstream_variables
      Gitlab::Ci::Variables::Downstream::Generator.new(self).calculate
    end

    def variables
      strong_memoize(:variables) do
        bridge_variables =
          if ::Feature.disabled?(:exclude_protected_variables_from_multi_project_pipeline_triggers, project) ||
              (expose_protected_project_variables? && expose_protected_group_variables?)
            scoped_variables
          else
            unprotected_scoped_variables(
              expose_project_variables: expose_protected_project_variables?,
              expose_group_variables: expose_protected_group_variables?
            )
          end

        Gitlab::Ci::Variables::Collection.new
         .concat(bridge_variables)
         .concat(pipeline.persisted_variables)
      end
    end

    def pipeline_variables
      pipeline.variables
    end

    def pipeline_schedule_variables
      return [] unless pipeline.pipeline_schedule

      pipeline.pipeline_schedule.variables.to_a
    end

    def forward_yaml_variables?
      strong_memoize(:forward_yaml_variables) do
        result = options&.dig(:trigger, :forward, :yaml_variables)

        result.nil? ? FORWARD_DEFAULTS[:yaml_variables] : result
      end
    end

    def forward_pipeline_variables?
      strong_memoize(:forward_pipeline_variables) do
        result = options&.dig(:trigger, :forward, :pipeline_variables)

        result.nil? ? FORWARD_DEFAULTS[:pipeline_variables] : result
      end
    end

    private

    def expose_protected_group_variables?
      return true if downstream_project.nil?
      return true if project.group.present? && project.group == downstream_project.group

      false
    end

    def expose_protected_project_variables?
      return true if downstream_project.nil?
      return true if project.id == downstream_project.id

      false
    end

    def cross_project_params
      {
        project: downstream_project,
        source: :pipeline,
        target_revision: {
          ref: target_ref || downstream_project.default_branch,
          variables_attributes: downstream_variables
        },
        execute_params: {
          ignore_skip_ci: true,
          bridge: self
        }
      }
    end

    def child_params
      parent_pipeline = pipeline

      {
        project: project,
        source: :parent_pipeline,
        target_revision: {
          ref: parent_pipeline.ref,
          checkout_sha: parent_pipeline.sha,
          before: parent_pipeline.before_sha,
          source_sha: parent_pipeline.source_sha,
          target_sha: parent_pipeline.target_sha,
          variables_attributes: downstream_variables
        },
        execute_params: {
          ignore_skip_ci: true,
          bridge: self,
          merge_request: parent_pipeline.merge_request
        }
      }
    end
  end
end

::Ci::Bridge.prepend_mod_with('Ci::Bridge')
