# frozen_string_literal: true

module RepositoryCheck
  class DispatchWorker
    include ApplicationWorker
    include CronjobQueue
    include ::EachShardWorker
    include ExclusiveLeaseGuard

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
