class RenameCodeToPath < ActiveRecord::Migration
  def up
    remove_column :projects, :code
    rename_column :namespaces, :code, :path
  end

  def down
    add_column :projects, :code, :string
    rename_column :namespaces, :path, :code
  end
end
