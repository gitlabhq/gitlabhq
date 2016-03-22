class IndexNamespacesOnVisibilityLevel < ActiveRecord::Migration
  def change
    unless index_exists?(:namespaces, :visibility_level)
      add_index :namespaces, :visibility_level
    end
  end
end
