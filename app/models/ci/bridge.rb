# frozen_string_literal: true

module Ci
  class Bridge < Ci::Processable
    include Ci::Contextable
    include Ci::Metadatable
    include Importable
    include AfterCommitQueue
    include Ci::HasRef

    InvalidBridgeTypeError = Class.new(StandardError)
    InvalidTransitionError = Class.new(StandardError)

    belongs_to :project
    belongs_to :trigger_request
    has_many :sourced_pipelines, class_name: "::Ci::Sources::Pipeline",
                                  foreign_key: :source_job_id

    has_one :sourced_pipeline, class_name: "::Ci::Sources::Pipeline", foreign_key: :source_job_id
    has_one :downstream_pipeline, through: :sourced_pipeline, source: :pipeline

    validates :ref, presence: true

    # rubocop:disable Cop/ActiveRecordSerialize
    serialize :options
    serialize :yaml_variables, ::Gitlab::Serializer::Ci::Variables
    # rubocop:enable Cop/ActiveRecordSerialize

    state_machine :status do
      after_transition [:created, :manual, :waiting_for_resource] => :pending do |bridge|
        next unless bridge.downstream_project

        bridge.run_after_commit do
          bridge.schedule_downstream_pipeline!
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
    end

    def self.retry(bridge, current_user)
      raise NotImplementedError
    end

    def self.with_preloads
      preload(
        :metadata,
        downstream_pipeline: [project: [:route, { namespace: :route }]],
        project: [:namespace]
      )
    end

    def schedule_downstream_pipeline!
      raise InvalidBridgeTypeError unless downstream_project

      ::Ci::CreateCrossProjectPipelineWorker.perform_async(self.id)
    end

    def inherit_status_from_downstream!(pipeline)
      case pipeline.status
      when 'success'
        self.success!
      when 'failed', 'canceled', 'skipped'
        self.drop!
      else
        false
      end
    end

    def has_downstream_pipeline?
      sourced_pipelines.exists?
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
        options&.dig(:trigger, :project)
      end
    end

    def parent_pipeline
      pipeline if triggers_child_pipeline?
    end

    def triggers_child_pipeline?
      yaml_for_downstream.present?
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

    # rubocop: disable CodeReuse/ServiceClass
    # We don't need it but we are taking `job_variables_attributes` parameter
    # to make it consistent with `Ci::Build#play` method.
    def play(current_user, job_variables_attributes = nil)
      Ci::PlayBridgeService
        .new(project, current_user)
        .execute(self)
    end
    # rubocop: enable CodeReuse/ServiceClass

    def artifacts?
      false
    end

    def runnable?
      false
    end

    def any_unmet_prerequisites?
      false
    end

    def expanded_environment_name
    end

    def persisted_environment
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

      scoped_variables.to_runner_variables.yield_self do |all_variables|
        ::ExpandVariables.expand(branch, all_variables)
      end
    end

    def dependent?
      strong_memoize(:dependent) do
        options&.dig(:trigger, :strategy) == 'depend'
      end
    end

    def downstream_variables
      variables = scoped_variables.concat(pipeline.persisted_variables)

      variables.to_runner_variables.yield_self do |all_variables|
        yaml_variables.to_a.map do |hash|
          { key: hash[:key], value: ::ExpandVariables.expand(hash[:value], all_variables) }
        end
      end
    end

    def target_revision_ref
      downstream_pipeline_params.dig(:target_revision, :ref)
    end

    private

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
