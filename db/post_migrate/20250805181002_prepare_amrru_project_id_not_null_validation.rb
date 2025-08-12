# frozen_string_literal: true

class PrepareAmrruProjectIdNotNullValidation < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  CONSTRAINT_NAME = :check_eca70345f1

  def up
    prepare_async_check_constraint_validation :approval_merge_request_rules_users, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation :approval_merge_request_rules_users, name: CONSTRAINT_NAME
  end
end
