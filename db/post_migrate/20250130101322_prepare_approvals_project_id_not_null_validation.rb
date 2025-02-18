# frozen_string_literal: true

class PrepareApprovalsProjectIdNotNullValidation < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  CONSTRAINT_NAME = :check_9da7c942dc

  def up
    prepare_async_check_constraint_validation :approvals, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation :approvals, name: CONSTRAINT_NAME
  end
end
