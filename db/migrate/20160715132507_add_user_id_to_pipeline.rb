class AddUserIdToPipeline < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  def change
    add_column :ci_commits, :user_id, :integer
  end
end
