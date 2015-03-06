class AddUniqueIndexToNamespace < ActiveRecord::Migration
  def change
    remove_index :namespaces, :name
    remove_index :namespaces, :path

    add_index :namespaces, :name, unique: true
    add_index :namespaces, :path, unique: true
  end
end
