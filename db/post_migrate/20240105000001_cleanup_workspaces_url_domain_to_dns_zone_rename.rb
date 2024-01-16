# frozen_string_literal: true

class CleanupWorkspacesUrlDomainToDnsZoneRename < Gitlab::Database::Migration[2.2]
  milestone '16.8'

  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_rename :workspaces, :url_domain, :dns_zone
  end

  def down
    undo_cleanup_concurrent_column_rename :workspaces, :url_domain, :dns_zone
  end
end
