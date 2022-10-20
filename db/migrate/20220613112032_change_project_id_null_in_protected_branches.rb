# frozen_string_literal: true

class ChangeProjectIdNullInProtectedBranches < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def up
    change_column_null :protected_branches, :project_id, true
  end

  def down
    change_column_null :protected_branches, :project_id, false
  end
end
