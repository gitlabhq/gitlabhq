class AddRepoSizeToDb < ActiveRecord::Migration
  def change
    add_column :projects, :repository_size, :float, default: 0
  end
end
