# frozen_string_literal: true

class AddNotNullCiDeletedObjectProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  disable_ddl_transaction!

  TABLE_NAME = :ci_deleted_objects
  COLUMN_NAME = :project_id

  def up
    add_not_null_constraint(TABLE_NAME, COLUMN_NAME)
  end

  def down
    remove_not_null_constraint(TABLE_NAME, COLUMN_NAME)
  end
end
