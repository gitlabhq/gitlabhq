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

      result = Cells::Leases::ReconciliationService.new.execute

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
