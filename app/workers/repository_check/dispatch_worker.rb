module RepositoryCheck
  class DispatchWorker
    include ApplicationWorker
    include CronjobQueue
    include ::EachShardWorker

    def perform
      return unless Gitlab::CurrentSettings.repository_checks_enabled

      each_eligible_shard do |shard_name|
        RepositoryCheck::BatchWorker.perform_async(shard_name)
      end
    end
  end
end
