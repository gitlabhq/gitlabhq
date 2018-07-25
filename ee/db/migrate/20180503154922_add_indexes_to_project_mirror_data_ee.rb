class AddIndexesToProjectMirrorDataEE < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :project_mirror_data, :last_successful_update_at
  end

  def down
    # rubocop:disable Migration/RemoveIndex
    remove_index :project_mirror_data, :last_successful_update_at if index_exists? :project_mirror_data, :last_successful_update_at
  end
end
