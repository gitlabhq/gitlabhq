class MigrateImportAttributesFromProjectToProjectMirrorData < ActiveRecord::Migration
  DOWNTIME = false

  def up
    add_column :project_mirror_data, :status, :string
    add_column :project_mirror_data, :jid, :string
    add_column :project_mirror_data, :last_update_at, :datetime_with_timezone
    add_column :project_mirror_data, :last_successful_update_at, :datetime_with_timezone
    add_column :project_mirror_data, :last_error, :text
  end

  def down
    remove_column :project_mirror_data, :status
    remove_column :project_mirror_data, :jid
    remove_column :project_mirror_data, :last_update_at
    remove_column :project_mirror_data, :last_successful_update_at
    remove_column :project_mirror_data, :last_error
  end
end
