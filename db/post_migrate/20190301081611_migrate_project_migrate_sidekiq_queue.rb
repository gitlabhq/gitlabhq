# frozen_string_literal: true

class MigrateProjectMigrateSidekiqQueue < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    sidekiq_queue_migrate 'project_migrate_hashed_storage', to: 'hashed_storage:hashed_storage_project_migrate'
  end

  def down
    sidekiq_queue_migrate 'hashed_storage:hashed_storage_project_migrate', to: 'project_migrate_hashed_storage'
  end
end
