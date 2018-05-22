class RemoveProjectMirrorDataCreatedAtUpdatedAt < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    # A project_mirror_data table created in EE would have these columns, but
    # one created in CE wouldn't. We don't actually need them, so let's remove them.
    remove_column :project_mirror_data, :created_at if column_exists?(:project_mirror_data, :created_at)
    remove_column :project_mirror_data, :updated_at if column_exists?(:project_mirror_data, :updated_at)
  end

  def down
    # The columns do not need to be re-added; no application logic ever used them,
    # and migrations that did have been modified to no longer do so.
  end
end
