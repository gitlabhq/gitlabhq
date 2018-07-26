class AddUserIdToBuild < ActiveRecord::Migration
  def change
    add_column :ci_builds, :user_id, :integer
  end
end
