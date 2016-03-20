class IndexNamespacesOnVisibilityLevel < ActiveRecord::Migration
  def change
    add_index :namespaces, :visibility_level
  end
end
