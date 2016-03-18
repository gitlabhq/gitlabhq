# Migration type: online
class RemovePublicFromNamespace < ActiveRecord::Migration
  def change
    remove_column :namespaces, :public, :boolean
  end
end
