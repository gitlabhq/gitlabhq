# frozen_string_literal: true

class AddNotNullConstraintCiPipelineChatDataProjectId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.6'

  TABLE_NAME = :ci_pipeline_chat_data
  COLUMN_NAME = :project_id
  CONSTRAINT_NAME = :check_f6412eda6f

  def up
    add_not_null_constraint(TABLE_NAME, COLUMN_NAME, constraint_name: CONSTRAINT_NAME, validate: true)
  end

  def down
    remove_not_null_constraint(TABLE_NAME, COLUMN_NAME, constraint_name: CONSTRAINT_NAME)
  end
end
