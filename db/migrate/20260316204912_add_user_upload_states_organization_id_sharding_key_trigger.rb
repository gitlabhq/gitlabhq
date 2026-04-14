# frozen_string_literal: true

class AddUserUploadStatesOrganizationIdShardingKeyTrigger < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def up
    install_sharding_key_assignment_trigger(
      table: :user_upload_states,
      sharding_key: :organization_id,
      parent_table: :user_uploads,
      parent_sharding_key: :organization_id,
      foreign_key: :user_upload_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :user_upload_states,
      sharding_key: :organization_id,
      parent_table: :user_uploads,
      parent_sharding_key: :organization_id,
      foreign_key: :user_upload_id
    )
  end
end
