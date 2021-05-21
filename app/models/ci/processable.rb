# frozen_string_literal: true

module Ci
  class Processable < ::CommitStatus
    include Gitlab::Utils::StrongMemoize
    extend ::Gitlab::Utils::Override

    has_one :resource, class_name: 'Ci::Resource', foreign_key: 'build_id', inverse_of: :processable

    belongs_to :resource_group, class_name: 'Ci::ResourceGroup', inverse_of: :processables

    accepts_nested_attributes_for :needs

    scope :preload_needs, -> { preload(:needs) }

    scope :with_needs, -> (names = nil) do
      needs = Ci::BuildNeed.scoped_build.select(1)
      needs = needs.where(name: names) if names
      where('EXISTS (?)', needs).preload(:needs)
    end

    scope :without_needs, -> (names = nil) do
      needs = Ci::BuildNeed.scoped_build.select(1)
      needs = needs.where(name: names) if names
      where('NOT EXISTS (?)', needs)
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
          Ci::ResourceGroups::AssignResourceFromResourceGroupWorker
            .perform_async(processable.resource_group_id)
        end
      end

      after_transition any => ::Ci::Processable.completed_statuses do |processable|
        next unless processable.with_resource_group?
        next unless processable.resource_group.release_resource_from(processable)

        processable.run_after_commit do
          Ci::ResourceGroups::AssignResourceFromResourceGroupWorker
            .perform_async(processable.resource_group_id)
        end
      end
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

    def aggregated_needs_names
      read_attribute(:aggregated_needs_names)
    end

    def schedulable?
      raise NotImplementedError
    end

    def action?
      raise NotImplementedError
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

      Gitlab::Ci::Variables::Collection.new.concat(
        Ci::JobVariable.where(job: all_dependencies).dotenv_source
      )
    end

    def all_dependencies
      if Feature.enabled?(:preload_associations_jobs_request_api_endpoint, project, default_enabled: :yaml)
        strong_memoize(:all_dependencies) do
          dependencies.all
        end
      else
        dependencies.all
      end
    end

    private

    def dependencies
      strong_memoize(:dependencies) do
        Ci::BuildDependencies.new(self)
      end
    end
  end
end
