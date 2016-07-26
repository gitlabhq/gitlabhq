class AddIndexForPipelineUserId < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def change
    add_concurrent_index :ci_commits, :user_id
  end
end
