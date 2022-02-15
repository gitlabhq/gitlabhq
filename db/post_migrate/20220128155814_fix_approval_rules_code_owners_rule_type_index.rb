# frozen_string_literal: true

class FixApprovalRulesCodeOwnersRuleTypeIndex < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'index_approval_rules_code_owners_rule_type'
  OLD_INDEX_NAME = 'index_approval_rules_code_owners_rule_type_old'
  TABLE = :approval_merge_request_rules
  COLUMN = :merge_request_id
  WHERE_CONDITION = 'rule_type = 2'

  disable_ddl_transaction!

  def up
    rename_index TABLE, INDEX_NAME, OLD_INDEX_NAME if index_exists_by_name?(TABLE, INDEX_NAME) && !index_exists_by_name?(TABLE, OLD_INDEX_NAME)

    add_concurrent_index TABLE, COLUMN, where: WHERE_CONDITION, name: INDEX_NAME

    remove_concurrent_index_by_name TABLE, OLD_INDEX_NAME
  end

  def down
    # No-op
  end
end
