# frozen_string_literal: true

module LooseForeignKeys
  class CleanupWorker
    include ApplicationWorker
    include Gitlab::ExclusiveLeaseHelpers
    include CronjobQueue # rubocop: disable Scalability/CronWorkerContext

    sidekiq_options retry: false
    feature_category :cell
    data_consistency :always
    idempotent!

    def perform
      # Add small buffer on MAX_RUNTIME to account for single long running
      # query or extra worker time after the cleanup.
      lock_ttl = ModificationTracker::MAX_RUNTIME + 20.seconds

      in_lock(self.class.name.underscore, ttl: lock_ttl, retries: 0) do
        stats = {}

        connection_name, base_model = current_connection_name_and_base_model

        Gitlab::Database::SharedModel.using_connection(base_model.connection) do
          stats = ProcessDeletedRecordsService.new(connection: base_model.connection).execute
          stats[:connection] = connection_name
        end

        log_extra_metadata_on_done(:stats, stats)
      end
    end

    private

    # Rotate the databases every minute
    #
    # If one DB is configured: every minute use the configured DB
    # If two DBs are configured (Main, CI): minute 1 -> Main, minute 2 -> CI
    def current_connection_name_and_base_model
      minutes_since_epoch = Time.current.to_i / 60
      connections_with_name = Gitlab::Database.database_base_models_with_gitlab_shared.to_a # this will never be empty
      connections_with_name[minutes_since_epoch % connections_with_name.count]
    end
  end
end
