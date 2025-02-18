# frozen_string_literal: true

class PrepareApprovalMergeRequestRuleSourcesProjectIdNotNullValidation < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  CONSTRAINT_NAME = :check_f82666a937

  def up
    prepare_async_check_constraint_validation :approval_merge_request_rule_sources, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation :approval_merge_request_rule_sources, name: CONSTRAINT_NAME
  end
end
