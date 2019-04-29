# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddIndexForCodeOwnerRuleTypeOnApprovalMergeRequestRules < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_CODE_OWNERS_RULES_UNIQUENESS_NAME = 'index_approval_rule_name_for_code_owners_rule_type'
  INDEX_CODE_OWNERS_RULES_QUERY_NAME = 'index_approval_rules_code_owners_rule_type'

  class ApprovalMergeRequestRule < ActiveRecord::Base
    include EachBatch

    enum rule_types: {
      regular: 1,
      code_owner: 2
    }
  end

  def up
    # Ensure only 1 code_owner rule per merge_request
    add_concurrent_index(
      :approval_merge_request_rules,
      [:merge_request_id, :rule_type, :name],
      unique: true,
      where: "rule_type = #{ApprovalMergeRequestRule.rule_types[:code_owner]}",
      name: INDEX_CODE_OWNERS_RULES_UNIQUENESS_NAME
    )

    # Support lookups for all code_owner rules per merge_request
    add_concurrent_index(
      :approval_merge_request_rules,
      [:merge_request_id, :rule_type],
      where: "rule_type = #{ApprovalMergeRequestRule.rule_types[:code_owner]}",
      name: INDEX_CODE_OWNERS_RULES_QUERY_NAME
    )
  end

  def down
    remove_concurrent_index_by_name(
      :approval_merge_request_rules,
      INDEX_CODE_OWNERS_RULES_UNIQUENESS_NAME
    )

    remove_concurrent_index_by_name(
      :approval_merge_request_rules,
      INDEX_CODE_OWNERS_RULES_QUERY_NAME
    )
  end
end
