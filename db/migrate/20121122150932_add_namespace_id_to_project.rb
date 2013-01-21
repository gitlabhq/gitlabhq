class AddNamespaceIdToProject < ActiveRecord::Migration
  def change
    rename_column :projects, :group_id, :namespace_id
  end
end
