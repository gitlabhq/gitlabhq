# frozen_string_literal: true

module LooseForeignKeys
  class CleanupWorker
    include ApplicationWorker
    include Gitlab::ExclusiveLeaseHelpers
    include CronjobQueue # rubocop: disable Scalability/CronWorkerContext

    feature_category :sharding
    data_consistency :always
    idempotent!

    def perform
      return if Feature.disabled?(:loose_foreign_key_cleanup, default_enabled: :yaml)

      in_lock(self.class.name.underscore, ttl: 1.hour, retries: 0) do
        # TODO: Iterate over the connections
        # https://gitlab.com/gitlab-org/gitlab/-/issues/341513
        stats = ProcessDeletedRecordsService.new(connection: ApplicationRecord.connection).execute
        log_extra_metadata_on_done(:stats, stats)
      end
    end
  end
end
