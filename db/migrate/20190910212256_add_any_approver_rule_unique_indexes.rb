# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddAnyApproverRuleUniqueIndexes < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  PROJECT_RULE_UNIQUE_INDEX = 'any_approver_project_rule_type_unique_index'
  MERGE_REQUEST_RULE_UNIQUE_INDEX = 'any_approver_merge_request_rule_type_unique_index'

  disable_ddl_transaction!

  def up
    add_concurrent_index(:approval_project_rules, [:project_id],
      where: "rule_type = 3",
      name: PROJECT_RULE_UNIQUE_INDEX, unique: true)

    add_concurrent_index(:approval_merge_request_rules, [:merge_request_id, :rule_type],
      where: "rule_type = 4",
      name: MERGE_REQUEST_RULE_UNIQUE_INDEX, unique: true)
  end

  def down
    remove_concurrent_index_by_name(:approval_project_rules, PROJECT_RULE_UNIQUE_INDEX)
    remove_concurrent_index_by_name(:approval_merge_request_rules, MERGE_REQUEST_RULE_UNIQUE_INDEX)
  end
end
