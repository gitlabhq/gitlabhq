# frozen_string_literal: true

module Namespaces
  class StuckTransfersCancelCronWorker
    include ApplicationWorker
    include ExclusiveLeaseGuard

    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext -- This is an instance-wide cleanup query

    idempotent!

    data_consistency :sticky
    urgency :low
    defer_on_database_health_signal :gitlab_main, [:namespaces], 1.minute
    feature_category :groups_and_projects

    def perform
      try_obtain_lease do
        ::Namespaces::CancelStuckTransfersService.new.execute
      end
    end

    private

    def lease_timeout
      30.minutes
    end
  end
end
