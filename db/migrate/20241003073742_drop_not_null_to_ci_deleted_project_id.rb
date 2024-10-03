# frozen_string_literal: true

class DropNotNullToCiDeletedProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  disable_ddl_transaction!

  TABLE_NAME = :ci_deleted_objects
  COLUMN_NAME = :project_id

  def up
    remove_not_null_constraint(TABLE_NAME, COLUMN_NAME)
  end

  def down
    add_not_null_constraint(TABLE_NAME, COLUMN_NAME, validate: false)
  end
end
