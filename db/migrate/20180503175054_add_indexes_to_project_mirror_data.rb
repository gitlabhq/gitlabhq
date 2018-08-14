class AddIndexesToProjectMirrorData < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :project_mirror_data, :jid
    add_concurrent_index :project_mirror_data, :status
  end

  def down
    # rubocop:disable Migration/RemoveIndex
    remove_index :project_mirror_data, :jid if index_exists? :project_mirror_data, :jid
    remove_index :project_mirror_data, :status if index_exists? :project_mirror_data, :status
  end
end
