# frozen_string_literal: true

class ScheduleIndexApprovalMergeRequestRulesOnConfigIdAndIdAndUpdatedAt < Gitlab::Database::Migration[2.2]
  milestone '16.10'

  INDEX_NAME = :idx_approval_mr_rules_on_config_id_and_id_and_updated_at
  TABLE_NAME = :approval_merge_request_rules
  COLUMNS = %i[security_orchestration_policy_configuration_id id updated_at]

  def up
    prepare_async_index(TABLE_NAME, COLUMNS, name: INDEX_NAME)
  end

  def down
    unprepare_async_index(TABLE_NAME, COLUMNS, name: INDEX_NAME)
  end
end
