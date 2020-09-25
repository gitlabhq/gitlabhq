# frozen_string_literal: true

module AuthorizedProjectUpdate
  class PeriodicRecalculateWorker
    include ApplicationWorker
    # This worker does not perform work scoped to a context
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    feature_category :source_code_management
    urgency :low

    idempotent!

    def perform
      AuthorizedProjectUpdate::PeriodicRecalculateService.new.execute
    end
  end
end
