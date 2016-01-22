class AddPendingDeleteToProject < ActiveRecord::Migration
  def change
    add_column :projects, :pending_delete, :boolean
  end
end
