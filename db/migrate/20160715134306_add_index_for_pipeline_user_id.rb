class AddIndexForPipelineUserId < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  def change
    add_concurrent_index :ci_commits, :user_id
  end
end
