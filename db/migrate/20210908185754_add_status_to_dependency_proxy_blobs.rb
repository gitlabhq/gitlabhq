# frozen_string_literal: true

class AddStatusToDependencyProxyBlobs < Gitlab::Database::Migration[1.0]
  def change
    add_column :dependency_proxy_blobs, :status, :smallint, default: 0, null: false
  end
end
