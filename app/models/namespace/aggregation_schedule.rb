# frozen_string_literal: true

class Namespace::AggregationSchedule < ApplicationRecord
  include AfterCommitQueue
  include ExclusiveLeaseGuard

  self.primary_key = :namespace_id

  REDIS_SHARED_KEY = 'gitlab:update_namespace_statistics_delay'

  belongs_to :namespace

  after_create :schedule_root_storage_statistics

  def default_lease_timeout
    ::Gitlab::CurrentSettings.namespace_aggregation_schedule_lease_duration_in_seconds
  end

  def schedule_root_storage_statistics
    run_after_commit_or_now do
      try_obtain_lease do
        Namespaces::RootStatisticsWorker
          .perform_async(namespace_id)

        Namespaces::RootStatisticsWorker
          .perform_in(default_lease_timeout, namespace_id)
      end
    end
  end

  private

  # Used by ExclusiveLeaseGuard
  def lease_timeout
    default_lease_timeout
  end

  # Used by ExclusiveLeaseGuard
  def lease_key
    "namespace:namespaces_root_statistics:#{namespace_id}"
  end

  # Used by ExclusiveLeaseGuard
  # Overriding value as we never release the lease
  # before the timeout in order to prevent multiple
  # RootStatisticsWorker to start in a short span of time
  def lease_release?
    false
  end
end
