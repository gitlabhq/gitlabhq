# frozen_string_literal: true

class AddShardingKeyTriggerToDesignManagementActionUploads < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  TABLE_NAME = :design_management_action_uploads
  SHARDING_KEY = :namespace_id
  PARENT_TABLE = :design_management_designs_versions
  PARENT_SHARDING_KEY = :namespace_id
  FOREIGN_KEY = :model_id

  def up
    install_sharding_key_assignment_trigger(
      table: TABLE_NAME,
      sharding_key: SHARDING_KEY,
      parent_table: PARENT_TABLE,
      parent_sharding_key: PARENT_SHARDING_KEY,
      foreign_key: FOREIGN_KEY
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: TABLE_NAME,
      sharding_key: SHARDING_KEY,
      parent_table: PARENT_TABLE,
      parent_sharding_key: PARENT_SHARDING_KEY,
      foreign_key: FOREIGN_KEY
    )
  end
end
