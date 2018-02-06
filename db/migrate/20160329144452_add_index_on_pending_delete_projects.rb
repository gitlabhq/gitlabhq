# rubocop:disable all
class AddIndexOnPendingDeleteProjects < ActiveRecord::Migration
  def change
    add_index :projects, :pending_delete
  end
end

