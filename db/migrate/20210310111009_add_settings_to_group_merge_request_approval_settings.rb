# frozen_string_literal: true

class AddSettingsToGroupMergeRequestApprovalSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    change_table(:group_merge_request_approval_settings, bulk: true) do |t|
      t.column :allow_committer_approval, :boolean, null: false, default: false
      t.column :allow_overrides_to_approver_list_per_merge_request, :boolean, null: false, default: false
      t.column :retain_approvals_on_push, :boolean, null: false, default: false
      t.column :require_password_to_approve, :boolean, null: false, default: false
    end
  end
end
