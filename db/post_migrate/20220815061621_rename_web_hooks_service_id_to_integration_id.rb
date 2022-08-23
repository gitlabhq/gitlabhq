# frozen_string_literal: true

class RenameWebHooksServiceIdToIntegrationId < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    rename_column_concurrently :web_hooks, :service_id, :integration_id
  end

  def down
    undo_rename_column_concurrently :web_hooks, :service_id, :integration_id
  end
end
