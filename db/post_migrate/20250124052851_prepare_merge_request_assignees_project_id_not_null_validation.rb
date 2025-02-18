# frozen_string_literal: true

class PrepareMergeRequestAssigneesProjectIdNotNullValidation < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  CONSTRAINT_NAME = :check_1442f79624

  def up
    prepare_async_check_constraint_validation :merge_request_assignees, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation :merge_request_assignees, name: CONSTRAINT_NAME
  end
end
