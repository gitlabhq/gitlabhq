class ChangeOwnerIdForGroup < ActiveRecord::Migration
  def up
    change_column :namespaces, :owner_id, :integer, null: true
  end

  def down
    change_column :namespaces, :owner_id, :integer, null: false
  end
end
