# frozen_string_literal: true

class AddIndexApprovalMrRulesOnConfigIdAndIdAndUpdatedAt < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  disable_ddl_transaction!

  INDEX_NAME = :idx_approval_mr_rules_on_config_id_and_id_and_updated_at
  TABLE_NAME = :approval_merge_request_rules

  def up
    add_concurrent_index(TABLE_NAME, %i[security_orchestration_policy_configuration_id id updated_at], name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
