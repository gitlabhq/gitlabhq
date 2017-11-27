# rubocop:disable Migration/AddColumnWithDefaultToLargeTable
# rubocop:disable Migration/UpdateLargeTable
class AddSquashToMergeRequests < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  DOWNTIME = false

  def up
    add_column_with_default :merge_requests, :squash, :boolean, default: false, allow_null: false
  end

  def down
    remove_column :merge_requests, :squash
  end
end
