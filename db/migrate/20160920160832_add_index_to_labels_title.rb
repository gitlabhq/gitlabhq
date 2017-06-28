# rubocop:disable RemoveIndex
class AddIndexToLabelsTitle < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :labels, :title
  end

  def down
    remove_index :labels, :title if index_exists? :labels, :title
  end
end
