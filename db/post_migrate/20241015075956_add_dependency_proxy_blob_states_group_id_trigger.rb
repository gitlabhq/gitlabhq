# frozen_string_literal: true

class AddDependencyProxyBlobStatesGroupIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def up
    install_sharding_key_assignment_trigger(
      table: :dependency_proxy_blob_states,
      sharding_key: :group_id,
      parent_table: :dependency_proxy_blobs,
      parent_sharding_key: :group_id,
      foreign_key: :dependency_proxy_blob_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :dependency_proxy_blob_states,
      sharding_key: :group_id,
      parent_table: :dependency_proxy_blobs,
      parent_sharding_key: :group_id,
      foreign_key: :dependency_proxy_blob_id
    )
  end
end
