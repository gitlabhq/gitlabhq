# frozen_string_literal: true

module Ci
  class ResourceGroup < Ci::ApplicationRecord
    belongs_to :project, inverse_of: :resource_groups

    has_many :resources, class_name: 'Ci::Resource', inverse_of: :resource_group
    has_many :processables, class_name: 'Ci::Processable', inverse_of: :resource_group

    validates :key,
      length: { maximum: 255 },
      format: { with: Gitlab::Regex.environment_name_regex,
                message: Gitlab::Regex.environment_name_regex_message }

    before_create :ensure_resource

    RESOURCE_GROUP_PROCESS_MODES = {
      unordered: 0,
      oldest_first: 1,
      newest_first: 2,
      newest_ready_first: 3
    }.freeze

    enum :process_mode, RESOURCE_GROUP_PROCESS_MODES

    ##
    # NOTE: This is concurrency-safe method that the subquery in the `UPDATE`
    # works as explicit locking.
    def assign_resource_to(processable)
      attrs = {
        build_id: processable.id,
        partition_id: processable.partition_id
      }

      success = resources.free.limit(1).update_all(attrs) > 0
      log_event(success: success, processable: processable, action: "assign resource to processable")

      success
    end

    def release_resource_from(processable)
      attrs = { build_id: nil, partition_id: nil }

      success = resources.retained_by(processable).update_all(attrs) > 0
      log_event(success: success, processable: processable, action: "release resource from processable")

      success
    end

    # In some cases, state machine hooks in `Ci::Build` are skipped
    # even if the job status transitions to a complete state.
    # For example, `Ci::Build#doom!` (a.k.a `data_integrity_failure`) doesn't execute state machine hooks.
    # To handle these edge cases, we check the staleness of the jobs that currently
    # assigned to the resources, and release if it's stale.
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/335537#note_632925914 for more information.
    def stale_processables
      # Resolve the retained `(build_id, partition_id)` pairs first so the
      # `p_ci_builds` lookup gets literal `partition_id` values and can prune
      # partitions at plan time. A correlated subquery cannot prune because
      # the planner does not know the partition IDs ahead of time.
      # rubocop:disable Database/AvoidUsingPluckWithoutLimit -- bounded by resource-group cardinality
      retained_pairs = resources.retained.pluck(:build_id, :partition_id)
      # rubocop:enable Database/AvoidUsingPluckWithoutLimit

      Ci::Processable.id_and_partition_in(retained_pairs).complete.updated_at_before(5.minutes.ago)
    end

    def upcoming_processables
      if unordered?
        processables.waiting_for_resource
      elsif oldest_first?
        processables.waiting_for_resource_or_upcoming
          .order(Arel.sql("commit_id ASC, #{sort_by_job_status}"))
      elsif newest_first?
        processables.waiting_for_resource_or_upcoming
          .order(Arel.sql("commit_id DESC, #{sort_by_job_status}"))
      elsif newest_ready_first?
        processables.waiting_for_resource
          .order(Arel.sql("commit_id DESC, #{sort_by_job_status}"))
      else
        Ci::Processable.none
      end
    end

    def current_processable
      Ci::Processable.find_by('(id, partition_id) IN (?)', resources.select('build_id, partition_id'))
    end

    private

    # In order to avoid deadlock, we do NOT specify the job execution order in the same pipeline.
    # The system processes wherever ready to transition to `pending` status from `waiting_for_resource`.
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/202186 for more information.
    def sort_by_job_status
      <<~SQL
        CASE status
          WHEN 'waiting_for_resource' THEN 0
          ELSE 1
        END ASC
      SQL
    end

    def ensure_resource
      # Currently we only support one resource per group, which means
      # maximum one build can be set to the resource group, thus builds
      # belong to the same resource group are executed once at time.
      self.resources.build if self.resources.empty?
    end

    def log_event(success:, processable:, action:)
      Gitlab::Ci::ResourceGroups::Logger.build.info({
        resource_group_id: self.id,
        processable_id: processable.id,
        message: "attempted to #{action}",
        success: success
      })
    end
  end
end
