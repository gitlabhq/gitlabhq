# frozen_string_literal: true

class AddCoverageMinimumThresholdCheckConstraints < Gitlab::Database::Migration[2.3]
  milestone '19.1'
  disable_ddl_transaction!

  def up
    add_check_constraint :approval_project_rules,
      'coverage_minimum_threshold IS NULL OR (coverage_minimum_threshold >= 0 AND coverage_minimum_threshold <= 100)',
      check_constraint_name(:approval_project_rules, :coverage_minimum_threshold, 'range')

    add_check_constraint :approval_merge_request_rules,
      'coverage_minimum_threshold IS NULL OR (coverage_minimum_threshold >= 0 AND coverage_minimum_threshold <= 100)',
      check_constraint_name(:approval_merge_request_rules, :coverage_minimum_threshold, 'range')
  end

  def down
    remove_check_constraint :approval_project_rules,
      check_constraint_name(:approval_project_rules, :coverage_minimum_threshold, 'range')

    remove_check_constraint :approval_merge_request_rules,
      check_constraint_name(:approval_merge_request_rules, :coverage_minimum_threshold, 'range')
  end
end
