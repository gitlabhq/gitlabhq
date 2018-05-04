class AddIndexesToProjectMirrorData < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :project_mirror_data, :last_successful_update_at
    add_concurrent_index :project_mirror_data, :jid
    add_concurrent_index :project_mirror_data, :status
  end

  def down
    remove_index :project_mirror_data, :last_successful_update_at if index_exists? :project_mirror_data, :last_successful_update_at
    remove_index :project_mirror_data, :jid if index_exists? :project_mirror_data, :jid
    remove_index :project_mirror_data, :status if index_exists? :project_mirror_data, :status
  end
end
