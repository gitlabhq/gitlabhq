class RenameResetApprovers < ActiveRecord::Migration
  def change
    rename_column :projects, :reset_approvers_on_push, :reset_approvals_on_push
  end
end
