# frozen_string_literal: true

module Cells
  class ScheduleClaimsVerificationWorker
    include ApplicationWorker
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext -- context is not needed

    deduplicate :until_executed
    idempotent!
    data_consistency :sticky
    feature_category :cell
    urgency :throttled
    queue_namespace :cronjob

    SCHEDULE_DELAY = 10.minutes

    def perform
      return unless Gitlab.config.cell.enabled

      models = models_with_claims

      models.each_with_index do |model, index|
        ClaimsVerificationWorker.perform_in(index * SCHEDULE_DELAY, model)
      end

      log_hash_metadata_on_done(
        message: "Scheduled #{models} for claims verification"
      )
    end

    private

    def models_with_claims
      Cells::Claimable.models_with_claims.map(&:name)
    end
  end
end
