# frozen_string_literal: true

class CleanupWebHooksServiceId < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :web_hooks, :service_id, :integration_id
  end

  def down
    undo_cleanup_concurrent_column_rename :web_hooks, :service_id, :integration_id
  end
end
