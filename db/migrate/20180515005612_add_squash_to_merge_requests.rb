# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddSquashToMergeRequests < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  DOWNTIME = false

  def up
    unless column_exists?(:merge_requests, :squash)
      # rubocop:disable Migration/UpdateLargeTable
      add_column_with_default :merge_requests, :squash, :boolean, default: false, allow_null: false # rubocop:disable Migration/AddColumnWithDefault
    end
  end

  def down
    remove_column :merge_requests, :squash if column_exists?(:merge_requests, :squash)
  end
end
