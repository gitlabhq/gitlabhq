# frozen_string_literal: true

class AddOperationsScopesProjectIdNotNull < Gitlab::Database::Migration[2.3]
  milestone '18.2'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :operations_scopes, :project_id
  end

  def down
    remove_not_null_constraint :operations_scopes, :project_id
  end
end
