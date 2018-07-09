class AddResyncWasScheduledAtToProjectRegistry < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :project_registry, :resync_repository_was_scheduled_at, :datetime_with_timezone
    add_column :project_registry, :resync_wiki_was_scheduled_at, :datetime_with_timezone
  end
end
