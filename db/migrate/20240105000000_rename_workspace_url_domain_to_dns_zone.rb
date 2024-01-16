# frozen_string_literal: true

class RenameWorkspaceUrlDomainToDnsZone < Gitlab::Database::Migration[2.2]
  milestone '16.8'
  disable_ddl_transaction!

  def up
    rename_column_concurrently :workspaces, :url_domain, :dns_zone
  end

  def down
    undo_rename_column_concurrently :workspaces, :url_domain, :dns_zone
  end
end
