# frozen_string_literal: true

module RepositoryCheck
  class DispatchWorker
    include ApplicationWorker
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext
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
