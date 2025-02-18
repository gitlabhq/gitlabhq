# frozen_string_literal: true

class AddPrepareNotNullConstraintForPipelineMessagesProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  disable_ddl_transaction!

  TABLE = :ci_pipeline_messages
  COLUMN = :project_id
  CONSTRAINT = :check_fe8ee122a2

  def up
    add_not_null_constraint(TABLE, COLUMN, constraint_name: CONSTRAINT, validate: false)
    prepare_async_check_constraint_validation(TABLE, name: CONSTRAINT)
  end

  def down
    unprepare_async_check_constraint_validation(TABLE, name: CONSTRAINT)
    drop_constraint(TABLE, CONSTRAINT)
  end
end
