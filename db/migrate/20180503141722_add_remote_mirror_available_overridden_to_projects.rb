class AddRemoteMirrorAvailableOverriddenToProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column(:projects, :remote_mirror_available_overridden, :boolean) unless column_exists?(:projects, :remote_mirror_available_overridden)
  end

  def down
    remove_column(:projects, :remote_mirror_available_overridden) if column_exists?(:projects, :remote_mirror_available_overridden)
  end
end
