# frozen_string_literal: true

class CleanupWorkspacesConfigVersionRename < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :workspaces, :config_version, :desired_config_generator_version
  end

  def down
    undo_cleanup_concurrent_column_rename :workspaces, :config_version, :desired_config_generator_version
  end
end
