# frozen_string_literal: true

class Namespace::AggregationSchedule < ApplicationRecord
  include AfterCommitQueue
  include ExclusiveLeaseGuard

  self.primary_key = :namespace_id

  DEFAULT_LEASE_TIMEOUT = 3.hours
  REDIS_SHARED_KEY = 'gitlab:update_namespace_statistics_delay'.freeze

  belongs_to :namespace

  after_create :schedule_root_storage_statistics

  def self.delay_timeout
    redis_timeout = Gitlab::Redis::SharedState.with do |redis|
      redis.get(REDIS_SHARED_KEY)
    end

    redis_timeout.nil? ? DEFAULT_LEASE_TIMEOUT : redis_timeout.to_i
  end

  def schedule_root_storage_statistics
    run_after_commit_or_now do
      try_obtain_lease do
        Namespaces::RootStatisticsWorker
          .perform_async(namespace_id)

        Namespaces::RootStatisticsWorker
          .perform_in(self.class.delay_timeout, namespace_id)
      end
    end
  end

  private

  # Used by ExclusiveLeaseGuard
  def lease_timeout
    self.class.delay_timeout
  end

  # Used by ExclusiveLeaseGuard
  def lease_key
    "namespace:namespaces_root_statistics:#{namespace_id}"
  end
end
