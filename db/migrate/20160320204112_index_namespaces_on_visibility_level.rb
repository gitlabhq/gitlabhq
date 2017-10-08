# rubocop:disable all
class IndexNamespacesOnVisibilityLevel < ActiveRecord::Migration[4.2]
  def change
    unless index_exists?(:namespaces, :visibility_level)
      add_index :namespaces, :visibility_level
    end
  end
end
