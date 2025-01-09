# frozen_string_literal: true

class RenameWorkspacesDevfileRefToProjectRef < Gitlab::Database::Migration[2.2]
  milestone '17.8'
  disable_ddl_transaction!

  def up
    rename_column_concurrently :workspaces, :devfile_ref, :project_ref
  end

  def down
    undo_rename_column_concurrently :workspaces, :devfile_ref, :project_ref
  end
end
