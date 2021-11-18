# frozen_string_literal: true

class AddReadAtToDependencyProxyManifests < Gitlab::Database::Migration[1.0]
  def change
    add_column :dependency_proxy_manifests, :read_at, :datetime_with_timezone, null: false, default: -> { 'NOW()' }
  end
end
