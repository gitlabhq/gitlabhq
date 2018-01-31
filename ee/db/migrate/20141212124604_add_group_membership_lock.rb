# rubocop:disable all
class AddGroupMembershipLock < ActiveRecord::Migration
  def change
    add_column :namespaces, :membership_lock, :boolean, default: false
  end
end
