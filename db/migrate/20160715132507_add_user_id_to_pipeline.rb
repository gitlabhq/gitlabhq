class AddUserIdToPipeline < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  def change
    add_column :ci_commits, :user_id, :integer
  end
end
