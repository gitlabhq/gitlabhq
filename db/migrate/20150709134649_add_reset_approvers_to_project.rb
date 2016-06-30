# rubocop:disable all
class AddResetApproversToProject < ActiveRecord::Migration
  def change
    add_column :projects, :reset_approvers_on_push, :boolean, default: true
  end
end
