# frozen_string_literal: true

class AddModifiedToApprovalMergeRequestRule < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :approval_merge_request_rules, :modified_from_project_rule, :boolean, default: false, null: false
  end
end
