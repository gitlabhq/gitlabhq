# frozen_string_literal: true

class PrepareMergeRequestReviewersProjectIdNotNullValidation < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.10'

  CONSTRAINT_NAME = :check_fb72c99774

  def up
    prepare_async_check_constraint_validation :merge_request_reviewers, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation :merge_request_reviewers, name: CONSTRAINT_NAME
  end
end
