class AddIndexUpdatedAtToIssues < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :issues, :updated_at
  end

  def down
    remove_concurrent_index :issues, :updated_at
  end
end
