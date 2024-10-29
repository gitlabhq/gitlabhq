# frozen_string_literal: true

class CleanupInstanceIntegrationsTypeRename < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :instance_integrations, :type, :type_new
  end

  def down
    undo_cleanup_concurrent_column_rename :instance_integrations, :type, :type_new
  end
end
