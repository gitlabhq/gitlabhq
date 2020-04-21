class EnsureMissingColumnsToProjectMirrorData < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # rubocop:disable Migration/AddLimitToTextColumns
  # rubocop:disable Migration/PreventStrings
  def up
    add_column :project_mirror_data, :status, :string unless column_exists?(:project_mirror_data, :status)
    add_column :project_mirror_data, :jid, :string unless column_exists?(:project_mirror_data, :jid)
    add_column :project_mirror_data, :last_error, :text unless column_exists?(:project_mirror_data, :last_error)
  end
  # rubocop:enable Migration/PreventStrings
  # rubocop:enable Migration/AddLimitToTextColumns

  def down
    # db/migrate/20180502122856_create_project_mirror_data.rb will remove the table
  end
end
