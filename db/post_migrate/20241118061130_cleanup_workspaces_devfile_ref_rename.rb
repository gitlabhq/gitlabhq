# frozen_string_literal: true

class CleanupWorkspacesDevfileRefRename < Gitlab::Database::Migration[2.2]
  milestone '17.8'
  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :workspaces, :devfile_ref, :project_ref
  end

  def down
    undo_cleanup_concurrent_column_rename :workspaces, :devfile_ref, :project_ref
  end
end
