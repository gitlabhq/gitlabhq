# frozen_string_literal: true

module Ci
  # This class is a collection of common features between Ci::Build and Ci::Bridge.
  # In https://gitlab.com/groups/gitlab-org/-/epics/9991, we aim to clarify class naming conventions.
  class Processable < ::CommitStatus
    include Gitlab::Utils::StrongMemoize
    include FromUnion
    include Ci::Metadatable
    extend ::Gitlab::Utils::Override

    ACTIONABLE_WHEN = %w[manual delayed].freeze

    self.allow_legacy_sti_class = true

    has_one :resource, class_name: 'Ci::Resource', foreign_key: 'build_id', inverse_of: :processable
    has_one :sourced_pipeline, class_name: 'Ci::Sources::Pipeline', foreign_key: :source_job_id, inverse_of: :source_job

    belongs_to :trigger_request
    belongs_to :resource_group, class_name: 'Ci::ResourceGroup', inverse_of: :processables

    delegate :trigger_short_token, to: :trigger_request, allow_nil: true

    accepts_nested_attributes_for :needs

    scope :preload_needs, -> { preload(:needs) }
    scope :manual_actions, -> { where(when: :manual, status: COMPLETED_STATUSES + %i[manual]) }

    scope :with_needs, ->(names = nil) do
      needs = Ci::BuildNeed.scoped_build.select(1)
      needs = needs.where(name: names) if names
      where('EXISTS (?)', needs)
    end

    scope :without_needs, ->(names = nil) do
      needs = Ci::BuildNeed.scoped_build.select(1)
      needs = needs.where(name: names) if names
      where('NOT EXISTS (?)', needs)
    end

    scope :interruptible, -> do
      joins(:metadata).merge(Ci::BuildMetadata.with_interruptible)
    end

    scope :not_interruptible, -> do
      joins(:metadata).where.not(
        Ci::BuildMetadata.table_name => { id: Ci::BuildMetadata.scoped_build.with_interruptible.select(:id) }
      )
    end

    state_machine :status do
      event :enqueue do
        transition [:created, :skipped, :manual, :scheduled] => :waiting_for_resource, if: :with_resource_group?
      end

      event :enqueue_scheduled do
        transition scheduled: :waiting_for_resource, if: :with_resource_group?
      end

      event :enqueue_waiting_for_resource do
        transition waiting_for_resource: :preparing, if: :any_unmet_prerequisites?
        transition waiting_for_resource: :pending
      end

      before_transition any => :waiting_for_resource do |processable|
        processable.waiting_for_resource_at = Time.current
      end

      before_transition on: :enqueue_waiting_for_resource do |processable|
        next unless processable.with_resource_group?

        processable.resource_group.assign_resource_to(processable)
      end

      after_transition any => :waiting_for_resource do |processable|
        processable.run_after_commit do
          assign_resource_from_resource_group(processable)
        end
      end

      after_transition any => ::Ci::Processable.completed_statuses do |processable|
        next unless processable.with_resource_group?

        processable.resource_group.release_resource_from(processable)

        processable.run_after_commit do
          assign_resource_from_resource_group(processable)
        end
      end

      after_transition any => [:failed] do |processable|
        next if processable.allow_failure?
        next unless processable.can_auto_cancel_pipeline_on_job_failure?

        processable.run_after_commit do
          processable.pipeline.cancel_async_on_job_failure
        end
      end
    end

    def assign_resource_from_resource_group(processable)
      Ci::ResourceGroups::AssignResourceFromResourceGroupWorker.perform_async(processable.resource_group_id)
    end

    def self.select_with_aggregated_needs(project)
      aggregated_needs_names = Ci::BuildNeed
        .scoped_build
        .select("ARRAY_AGG(name)")
        .to_sql

      all.select(
        '*',
        "(#{aggregated_needs_names}) as aggregated_needs_names"
      )
    end

    # Old processables may have scheduling_type as nil,
    # so we need to ensure the data exists before using it.
    def self.populate_scheduling_type!
      needs = Ci::BuildNeed.scoped_build.select(1)
      where(scheduling_type: nil).update_all(
        "scheduling_type = CASE WHEN (EXISTS (#{needs.to_sql}))
         THEN #{scheduling_types[:dag]}
         ELSE #{scheduling_types[:stage]}
         END"
      )
    end

    validates :type, presence: true
    validates :scheduling_type, presence: true, on: :create, unless: :importing?

    delegate :merge_request?,
      :merge_request_ref?,
      :legacy_detached_merge_request_pipeline?,
      :merge_train_pipeline?,
      to: :pipeline

    def clone(current_user:, new_job_variables_attributes: [])
      new_attributes = self.class.clone_accessors.index_with do |attribute|
        public_send(attribute) # rubocop:disable GitlabSecurity/PublicSend
      end

      if persisted_environment.present?
        new_attributes[:metadata_attributes] ||= {}
        new_attributes[:metadata_attributes][:expanded_environment_name] = expanded_environment_name
      end

      new_attributes[:user] = current_user

      self.class.new(new_attributes)
    end

    # Scoped user is present when the user creating the pipeline supports composite identity.
    # For example: a service account like GitLab Duo. The scoped user is used to further restrict
    # the permissions of the CI job token associated to the `job.user`.
    def scoped_user
      # If jobs are retried by human users (not composite identity) we want to
      # ignore the persisted `scoped_user_id`, because that is propagated
      # together with `options` to cloned jobs.
      # We also handle the case where `user` is `nil` (legacy behavior in specs).
      return unless user&.has_composite_identity?

      User.find_by_id(options[:scoped_user_id])
    end
    strong_memoize_attr :scoped_user

    def retryable?
      return false if retried? || archived? || deployment_rejected?

      success? || failed? || canceled? || canceling?
    end

    def aggregated_needs_names
      read_attribute(:aggregated_needs_names)
    end

    def schedulable?
      raise NotImplementedError
    end

    def action?
      raise NotImplementedError
    end

    def can_auto_cancel_pipeline_on_job_failure?
      raise NotImplementedError
    end

    def other_manual_actions
      pipeline.manual_actions.reject { |action| action.name == name }
    end

    def when
      read_attribute(:when) || 'on_success'
    end

    def expanded_environment_name
      raise NotImplementedError
    end

    def persisted_environment
      raise NotImplementedError
    end

    override :all_met_to_become_pending?
    def all_met_to_become_pending?
      super && !with_resource_group?
    end

    def with_resource_group?
      self.resource_group_id.present?
    end

    # Overriding scheduling_type enum's method for nil `scheduling_type`s
    def scheduling_type_dag?
      scheduling_type.nil? ? find_legacy_scheduling_type == :dag : super
    end

    # scheduling_type column of previous builds/bridges have not been populated,
    # so we calculate this value on runtime when we need it.
    def find_legacy_scheduling_type
      strong_memoize(:find_legacy_scheduling_type) do
        needs.exists? ? :dag : :stage
      end
    end

    def needs_attributes
      strong_memoize(:needs_attributes) do
        needs.map { |need| need.attributes.except('id', 'build_id') }
      end
    end

    def ensure_scheduling_type!
      # If this has a scheduling_type, it means all processables in the pipeline already have.
      return if scheduling_type

      pipeline.ensure_scheduling_type!
      reset
    end

    def dependency_variables
      return [] if all_dependencies.empty?

      dependencies_with_accessible_artifacts = job_dependencies_with_accessible_artifacts(all_dependencies)

      Gitlab::Ci::Variables::Collection.new.concat(
        Ci::JobVariable.where(job: dependencies_with_accessible_artifacts).dotenv_source
      )
    end

    def job_dependencies_with_accessible_artifacts(all_dependencies)
      build_ids = all_dependencies.collect(&:id)

      Ci::Build.id_in(build_ids).builds_with_accessible_artifacts(self.project_id)
    end

    def all_dependencies
      strong_memoize(:all_dependencies) do
        dependencies.all
      end
    end

    def manual_job?
      self.when == 'manual'
    end

    def manual_confirmation_message
      options[:manual_confirmation] if manual_job?
    end

    private

    def dependencies
      strong_memoize(:dependencies) do
        Ci::BuildDependencies.new(self)
      end
    end
  end
end
