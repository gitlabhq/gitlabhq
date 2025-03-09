# frozen_string_literal: true

class AddProjectIdToApprovalMergeRequestRulesUsers < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def change
    add_column :approval_merge_request_rules_users, :project_id, :bigint
  end
end
