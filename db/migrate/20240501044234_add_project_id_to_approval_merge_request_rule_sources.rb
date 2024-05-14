# frozen_string_literal: true

class AddProjectIdToApprovalMergeRequestRuleSources < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  def change
    add_column :approval_merge_request_rule_sources, :project_id, :bigint
  end
end
