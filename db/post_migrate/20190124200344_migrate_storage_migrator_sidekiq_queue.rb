# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class MigrateStorageMigratorSidekiqQueue < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    sidekiq_queue_migrate 'storage_migrator', to: 'hashed_storage:hashed_storage_migrator'
  end

  def down
    sidekiq_queue_migrate 'hashed_storage:hashed_storage_migrator', to: 'storage_migrator'
  end
end
