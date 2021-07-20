# frozen_string_literal: true

class MigrateUsagePingSidekiqQueue < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  # rubocop:disable Migration/SidekiqQueueMigrate
  def up
    sidekiq_queue_migrate 'cronjob:gitlab_usage_ping', to: 'cronjob:gitlab_service_ping'
  end

  def down
    sidekiq_queue_migrate 'cronjob:gitlab_service_ping', to: 'cronjob:gitlab_usage_ping'
  end
  # rubocop:enable Migration/SidekiqQueueMigrate
end
