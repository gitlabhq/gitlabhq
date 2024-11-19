# frozen_string_literal: true

class DropColumnDnsZoneFromWorkspacesTable < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  disable_ddl_transaction!

  def up
    remove_column :workspaces, :dns_zone, if_exists: true
  end

  def down
    add_column :workspaces, :dns_zone, :text, if_not_exists: true

    add_text_limit :workspaces, :dns_zone, 256
  end
end
