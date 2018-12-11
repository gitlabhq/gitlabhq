# rubocop:disable all
class AddPendingDeleteToProject < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :pending_delete, :boolean, default: false
  end
end
