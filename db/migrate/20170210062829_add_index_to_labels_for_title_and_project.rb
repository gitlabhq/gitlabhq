# rubocop:disable RemoveIndex
class AddIndexToLabelsForTitleAndProject < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :labels, :title
    add_concurrent_index :labels, :project_id
  end

  def down
    remove_index :labels, :title if index_exists? :labels, :title
    remove_index :labels, :project_id if index_exists? :labels, :project_id
  end
end
