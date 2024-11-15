# frozen_string_literal: true

module Members
  class SchedulePruneDeletionsWorker
    include ApplicationWorker
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext -- limited capacity scheduler

    feature_category :seat_cost_management
    data_consistency :sticky
    urgency :low

    idempotent!

    def perform
      Members::PruneDeletionsWorker.perform_with_capacity
    end
  end
end
