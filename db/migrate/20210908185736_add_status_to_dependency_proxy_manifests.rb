# frozen_string_literal: true

class AddStatusToDependencyProxyManifests < Gitlab::Database::Migration[1.0]
  def change
    add_column :dependency_proxy_manifests, :status, :smallint, default: 0, null: false
  end
end
