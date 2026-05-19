# frozen_string_literal: true

class AddWebserverLastSeenAtToZoektNodes < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def change
    add_column :zoekt_nodes, :webserver_last_seen_at, :timestamptz, null: true
  end
end
