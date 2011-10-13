class AddAllowRepoCreationForUser < ActiveRecord::Migration
  def up
    add_column :users, :allowed_create_repo, :boolean, :default => true, :null => false
  end

  def down
    remove_column :users, :allowed_create_repo
  end
end
