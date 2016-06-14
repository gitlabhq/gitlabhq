class AddRepositoryStorageToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :repository_storage, :string
  end
end
