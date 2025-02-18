# frozen_string_literal: true

class PrepareStatusCheckResponsesProjectIdNotNullValidation < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  CONSTRAINT_NAME = :check_29114cce9c

  def up
    prepare_async_check_constraint_validation :status_check_responses, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation :status_check_responses, name: CONSTRAINT_NAME
  end
end
