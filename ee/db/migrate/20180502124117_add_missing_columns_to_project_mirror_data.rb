# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddMissingColumnsToProjectMirrorData < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # Columns missing when a CE instance is upgraded to EE
    unless column_exists? :project_mirror_data, :retry_count
      add_column_with_default :project_mirror_data, :retry_count, :integer, default: 0, allow_null: false
      add_column :project_mirror_data, :last_update_started_at, :datetime
      add_column :project_mirror_data, :last_update_scheduled_at, :datetime
      add_column :project_mirror_data, :next_execution_timestamp, :datetime
    end

    # Columns missing on an EE instance
    unless column_exists? :project_mirror_data, :status
      add_column :project_mirror_data, :status, :string
      add_column :project_mirror_data, :jid, :string
      add_column :project_mirror_data, :last_update_at, :datetime_with_timezone
      add_column :project_mirror_data, :last_successful_update_at, :datetime_with_timezone
      add_column :project_mirror_data, :last_error, :text
    end
  end

  def down
    if column_exists? :project_mirror_data, :retry_count
      remove_column :project_mirror_data, :retry_count
      remove_column :project_mirror_data, :last_update_started_at
      remove_column :project_mirror_data, :last_update_scheduled_at
      remove_column :project_mirror_data, :next_execution_timestamp
    end

    if column_exists? :project_mirror_data, :status
      remove_column :project_mirror_data, :status
      remove_column :project_mirror_data, :jid
      remove_column :project_mirror_data, :last_update_at
      remove_column :project_mirror_data, :last_successful_update_at
      remove_column :project_mirror_data, :last_error
    end
  end
end
