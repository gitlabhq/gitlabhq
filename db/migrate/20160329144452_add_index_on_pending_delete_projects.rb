# rubocop:disable all
class AddIndexOnPendingDeleteProjects < ActiveRecord::Migration[4.2]
  def change
    add_index :projects, :pending_delete
  end
end

