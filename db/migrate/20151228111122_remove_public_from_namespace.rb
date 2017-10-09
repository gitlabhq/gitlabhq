# rubocop:disable all
# Migration type: online
class RemovePublicFromNamespace < ActiveRecord::Migration[4.2]
  def change
    remove_column :namespaces, :public, :boolean
  end
end
