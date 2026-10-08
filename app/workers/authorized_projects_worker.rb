# frozen_string_literal: true

class AuthorizedProjectsWorker
  include ApplicationWorker

  data_consistency :sticky

  worker_resource_boundary :cpu

  sidekiq_options retry: 3

  feature_category :permissions
  urgency :high
  weight 2

  deduplicate :until_executed, if_deduplicated: :reschedule_once, including_scheduled: true

  idempotent!

  defer_on_database_health_signal :gitlab_main_org, [], 1.minute,
    indicators: [Gitlab::Database::HealthStatus::Indicators::WalRate]

  def self.defer_on_database_health_signal?
    Feature.enabled?(:defer_primary_auth_refresh_on_wal_rate, :instance)
  end

  def perform(user_id)
    user = User.find_by_id(user_id)

    return unless user

    Users::RefreshAuthorizedProjectsService.new(user, source: self.class.name).execute
  end
end
