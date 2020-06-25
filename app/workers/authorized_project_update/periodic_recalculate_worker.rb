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
      if ::Feature.enabled?(:periodic_project_authorization_recalculation, default_enabled: true)
        AuthorizedProjectUpdate::PeriodicRecalculateService.new.execute
      end
    end
  end
end
