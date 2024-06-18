# frozen_string_literal: true

class AddProjectIdToApprovalMergeRequestRules < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def change
    add_column :approval_merge_request_rules, :project_id, :bigint
  end
end
