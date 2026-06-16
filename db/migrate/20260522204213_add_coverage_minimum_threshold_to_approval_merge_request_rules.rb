# frozen_string_literal: true

class AddCoverageMinimumThresholdToApprovalMergeRequestRules < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  def up
    add_column :approval_merge_request_rules, :coverage_minimum_threshold, :float, null: true, if_not_exists: true
  end

  def down
    remove_column :approval_merge_request_rules, :coverage_minimum_threshold, if_exists: true
  end
end
