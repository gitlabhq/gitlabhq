# rubocop:disable Migration/UpdateLargeTable
class AddSquashToMergeRequestsEE < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  DOWNTIME = false

  def up
    unless column_exists?(:merge_requests, :squash)
      add_column_with_default :merge_requests, :squash, :boolean, default: false, allow_null: false
    end
  end

  def down
    remove_column :merge_requests, :squash if column_exists?(:merge_requests, :squash)
  end
end
