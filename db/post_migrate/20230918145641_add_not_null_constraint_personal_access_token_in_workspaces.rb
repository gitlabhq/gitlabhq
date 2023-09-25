# frozen_string_literal: true

class AddNotNullConstraintPersonalAccessTokenInWorkspaces < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_not_null_constraint :workspaces, :personal_access_token_id, validate: false
  end

  def down
    remove_not_null_constraint :workspaces, :personal_access_token_id
  end
end
