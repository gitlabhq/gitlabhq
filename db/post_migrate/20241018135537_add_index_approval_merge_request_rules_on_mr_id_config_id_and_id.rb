# frozen_string_literal: true

class AddIndexApprovalMergeRequestRulesOnMrIdConfigIdAndId < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  INDEX_NAME = :idx_approval_merge_request_rules_on_mr_id_config_id_and_id
  TABLE_NAME = :approval_merge_request_rules

  def up
    add_concurrent_index(
      TABLE_NAME, %i[merge_request_id security_orchestration_policy_configuration_id id], name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
