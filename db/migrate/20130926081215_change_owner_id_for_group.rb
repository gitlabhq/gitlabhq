# rubocop:disable all
class ChangeOwnerIdForGroup < ActiveRecord::Migration[4.2]
  def up
    change_column :namespaces, :owner_id, :integer, null: true
  end

  def down
    change_column :namespaces, :owner_id, :integer, null: false
  end
end
