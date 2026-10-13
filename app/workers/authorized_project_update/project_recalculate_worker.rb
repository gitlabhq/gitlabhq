# frozen_string_literal: true

module AuthorizedProjectUpdate
  class ProjectRecalculateWorker
    include ApplicationWorker

    data_consistency :sticky

    feature_category :permissions
    urgency :high
    queue_namespace :authorized_project_update

    deduplicate :until_executed, if_deduplicated: :reschedule_once, including_scheduled: true

    idempotent!

    defer_on_database_health_signal :gitlab_main_org, [], 1.minute,
      indicators: [Gitlab::Database::HealthStatus::Indicators::WalRate]

    def self.defer_on_database_health_signal?
      Feature.enabled?(:defer_primary_auth_refresh_on_wal_rate, :instance)
    end

    def perform(project_id)
      project = Project.find_by_id(project_id)
      return unless project

      AuthorizedProjectUpdate::ProjectRecalculateService.new(project).execute
    end
  end
end
