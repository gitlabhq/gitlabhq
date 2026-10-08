# frozen_string_literal: true

module AuthorizedProjectUpdate
  class PeriodicRecalculateWorker
    include ApplicationWorker

    data_consistency :sticky

    # This worker does not perform work scoped to a context
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    feature_category :permissions
    urgency :low

    idempotent!

    defer_on_database_health_signal :gitlab_main_org, [], 5.minutes,
      indicators: [Gitlab::Database::HealthStatus::Indicators::WalRate]

    def self.defer_on_database_health_signal?
      Feature.enabled?(:defer_safety_net_auth_refresh_on_wal_rate, :instance)
    end

    def perform
      return if Feature.enabled?(:do_not_run_safety_net_auth_refresh_jobs, :instance)

      AuthorizedProjectUpdate::PeriodicRecalculateService.new.execute
    end
  end
end
