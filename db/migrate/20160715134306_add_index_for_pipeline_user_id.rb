class AddIndexForPipelineUserId < ActiveRecord::Migration
  DOWNTIME = false

  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def change
    add_concurrent_index :ci_commits, :user_id
  end
end
