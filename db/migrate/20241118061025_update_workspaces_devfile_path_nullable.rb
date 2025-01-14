# frozen_string_literal: true

class UpdateWorkspacesDevfilePathNullable < Gitlab::Database::Migration[2.2]
  milestone '17.8'
  disable_ddl_transaction!

  def up
    change_column_null :workspaces, :devfile_path, true
  end

  def down
    change_column_null :workspaces, :devfile_path, false
  end
end
