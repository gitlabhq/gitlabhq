# frozen_string_literal: true

module Gitlab
  module Metrics
    module Samplers
      # Exports the state of the deletion-scheduled backlog: the age of the oldest
      # record still awaiting deletion, and the number of records overdue past
      # their expected hard-deletion date. Age alone can be skewed by a single
      # stuck record, so the overdue count is exported alongside it. Both projects
      # and groups are covered, since deletion scheduling for either sets
      # namespace_details.deletion_scheduled_at. See
      # https://gitlab.com/gitlab-org/gitlab/-/work_items/621640.
      class DeletionScheduledBacklogSampler < BaseSampler
        include ExclusiveLeaseGuard

        DEFAULT_SAMPLING_INTERVAL_SECONDS = 5.minutes.to_i
        LEASE_TIMEOUT = 5.minutes

        OLDEST_AGE_METRIC = :gitlab_deletion_scheduled_backlog_oldest_age_seconds
        OVERDUE_COUNT_METRIC = :gitlab_deletion_scheduled_backlog_overdue_count

        # Grace period on top of the adjournment window. A record is only overdue
        # once it is past its expected hard-deletion date (deletion_adjourned_period
        # after it was scheduled) plus this slack, so records still within their
        # normal retention window are not counted.
        OVERDUE_SLACK = 2.days

        def oldest_age_metric
          @oldest_age_metric ||= ::Gitlab::Metrics.gauge(
            OLDEST_AGE_METRIC,
            'Age in seconds of the oldest record in the deletion-scheduled backlog'
          )
        end

        def overdue_count_metric
          @overdue_count_metric ||= ::Gitlab::Metrics.gauge(
            OVERDUE_COUNT_METRIC,
            'Number of records in the deletion-scheduled backlog past the expected deletion window'
          )
        end

        def sample
          return unless enabled?

          try_obtain_lease do
            use_primary do
              oldest_age_metric.set({}, oldest_age_seconds)
              overdue_count_metric.set({}, overdue_count)
            end
          end
        end

        private

        def lease_timeout
          LEASE_TIMEOUT
        end

        def enabled?
          ::Feature.enabled?(:deletion_scheduled_backlog_metric, Feature.current_pod, type: :ops)
        end

        def use_primary(&block)
          ::Gitlab::Database::LoadBalancing::SessionMap
            .current(ApplicationRecord.load_balancer)
            .use_primary(&block)
        end

        def oldest_age_seconds
          oldest = Namespace::Detail.oldest_deletion_scheduled_at
          return 0 unless oldest

          [Time.current - oldest, 0].max.round
        end

        def overdue_count
          Namespace::Detail.deletion_scheduled_before(overdue_cutoff).count
        end

        def overdue_cutoff
          (::Gitlab::CurrentSettings.deletion_adjourned_period.days + OVERDUE_SLACK).ago
        end
      end
    end
  end
end
