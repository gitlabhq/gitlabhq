# frozen_string_literal: true

class AddGroupIdToDependencyProxyManifestStates < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def change
    add_column :dependency_proxy_manifest_states, :group_id, :bigint
  end
end
