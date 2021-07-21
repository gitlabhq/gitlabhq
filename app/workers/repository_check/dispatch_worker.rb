# frozen_string_literal: true

module RepositoryCheck
  class DispatchWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    # rubocop:disable Scalability/CronWorkerContext
    # This worker does not perform work scoped to a context
    include CronjobQueue
    # rubocop:enable Scalability/CronWorkerContext
    include ::EachShardWorker
    include ExclusiveLeaseGuard

    feature_category :source_code_management

    LEASE_TIMEOUT = 1.hour

    def perform
      return unless Gitlab::CurrentSettings.repository_checks_enabled

      try_obtain_lease do
        each_eligible_shard do |shard_name|
          RepositoryCheck::BatchWorker.perform_async(shard_name)
        end
      end
    end

    def lease_timeout
      LEASE_TIMEOUT
    end
  end
end
