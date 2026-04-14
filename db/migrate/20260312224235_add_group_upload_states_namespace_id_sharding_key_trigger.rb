# frozen_string_literal: true

class AddGroupUploadStatesNamespaceIdShardingKeyTrigger < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def up
    install_sharding_key_assignment_trigger(
      table: :group_upload_states,
      sharding_key: :namespace_id,
      parent_table: :namespace_uploads,
      parent_sharding_key: :namespace_id,
      foreign_key: :group_upload_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :group_upload_states,
      sharding_key: :namespace_id,
      parent_table: :namespace_uploads,
      parent_sharding_key: :namespace_id,
      foreign_key: :group_upload_id
    )
  end
end
