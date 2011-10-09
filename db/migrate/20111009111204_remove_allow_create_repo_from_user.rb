class RemoveAllowCreateRepoFromUser < ActiveRecord::Migration
  def up
    remove_column :users, :allowed_create_repo
  end

  def down
    add_column :users, :allowed_create_repo, :boolean, :default => true, :null => false
  end
end
