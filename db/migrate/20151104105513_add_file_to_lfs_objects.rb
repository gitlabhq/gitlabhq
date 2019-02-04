class AddFileToLfsObjects < ActiveRecord::Migration[4.2]
  def change
    add_column :lfs_objects, :file, :string
  end
end
