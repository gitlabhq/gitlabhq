class AddFileToLfsObjects < ActiveRecord::Migration
  def change
    add_column :lfs_objects, :file, :string
  end
end
