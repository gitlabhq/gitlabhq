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
      connection_name, base_model = current_connection_name_and_base_model
      modification_tracker, turbo_mode = initialize_modification_tracker_for(connection_name)

      # Add small buffer on MAX_RUNTIME to account for single long running
      # query or extra worker time after the cleanup.
      lock_ttl = modification_tracker.max_runtime + 10.seconds

      in_lock(self.class.name.underscore, ttl: lock_ttl, retries: 0) do
        stats = ProcessDeletedRecordsService.new(
          connection: base_model.connection,
          modification_tracker: modification_tracker,
          logger: Sidekiq.logger
        ).execute
        stats[:connection] = connection_name
        stats[:turbo_mode] = turbo_mode

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

    def initialize_modification_tracker_for(connection_name)
      turbo_mode = turbo_mode?(connection_name)
      modification_tracker ||= turbo_mode ? TurboModificationTracker.new : ModificationTracker.new
      [modification_tracker, turbo_mode]
    end

    def turbo_mode?(connection_name)
      %w[main ci sec].include?(connection_name) &&
        Feature.enabled?(:"loose_foreign_keys_turbo_mode_#{connection_name}", type: :ops)
    end
  end
end
