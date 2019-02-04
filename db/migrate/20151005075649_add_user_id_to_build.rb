class AddUserIdToBuild < ActiveRecord::Migration[4.2]
  def change
    add_column :ci_builds, :user_id, :integer
  end
end
