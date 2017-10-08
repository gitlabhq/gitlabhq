# rubocop:disable all
class AddGroupShareLock < ActiveRecord::Migration[4.2]
  def change
    add_column :namespaces, :share_with_group_lock, :boolean, default: false
  end
end
