# frozen_string_literal: true

module AuthorizedProjectUpdate
  class PeriodicRecalculateWorker
    include ApplicationWorker

    data_consistency :sticky, feature_flag: :change_data_consistency_for_permissions_workers

    # This worker does not perform work scoped to a context
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    feature_category :permissions
    urgency :low

    idempotent!

    def perform
      AuthorizedProjectUpdate::PeriodicRecalculateService.new.execute
    end
  end
end
