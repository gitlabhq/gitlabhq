# frozen_string_literal: true

class AddNotNullConstraintToPathLocks < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :path_locks, :project_id
  end

  def down
    remove_not_null_constraint :path_locks, :project_id
  end
end
