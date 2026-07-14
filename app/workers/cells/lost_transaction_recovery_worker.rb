# frozen_string_literal: true

module Cells
  class LostTransactionRecoveryWorker
    include ApplicationWorker
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext -- context is not needed

    sidekiq_options retry: 3

    data_consistency :sticky
    feature_category :cell
    urgency :low
    queue_namespace :cronjob
    idempotent!

    defer_on_database_health_signal :gitlab_main, [:cells_outstanding_leases], 1.minute

    def perform
      return unless ::Current.cells_claims_leases?

      # Reconcile the recent window cheaply every run; once an hour do a full scan, which also
      # cleans up orphaned leases and catches any lease older than the window. Assumes this
      # cronjob runs at least once a minute.
      full_scan = Time.current.min == 0

      result = Cells::Leases::ReconciliationService.new.execute(full_scan: full_scan)

      log_hash_metadata_on_done(
        message: 'Lost transaction recovery completed',
        feature_category: :cell,
        processed_leases: result[:processed],
        committed_leases: result[:committed],
        rolled_back_leases: result[:rolled_back],
        pending_leases: result[:pending],
        orphaned_leases: result[:orphaned]
      )
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(e, feature_category: :cell)
      raise
    end
  end
end
