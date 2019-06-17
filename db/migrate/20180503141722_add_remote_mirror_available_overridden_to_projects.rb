class AddRemoteMirrorAvailableOverriddenToProjects < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column(:projects, :remote_mirror_available_overridden, :boolean) unless column_exists?(:projects, :remote_mirror_available_overridden)
  end

  def down
    # ee/db/migrate/20171017130239_add_remote_mirror_available_overridden_to_projects_ee.rb will remove the column.
  end
end
