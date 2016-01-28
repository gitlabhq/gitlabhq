class AddPendingDeleteToProject < ActiveRecord::Migration
  def change
    add_column :projects, :pending_delete, :boolean, default: false
  end
end
