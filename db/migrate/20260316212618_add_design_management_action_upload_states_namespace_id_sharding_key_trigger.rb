# frozen_string_literal: true

class AddDesignManagementActionUploadStatesNamespaceIdShardingKeyTrigger < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def up
    install_sharding_key_assignment_trigger(
      table: :design_management_action_upload_states,
      sharding_key: :namespace_id,
      parent_table: :design_management_action_uploads,
      parent_sharding_key: :namespace_id,
      foreign_key: :design_management_action_upload_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :design_management_action_upload_states,
      sharding_key: :namespace_id,
      parent_table: :design_management_action_uploads,
      parent_sharding_key: :namespace_id,
      foreign_key: :design_management_action_upload_id
    )
  end
end
