# frozen_string_literal: true

class AddOrganizationDetailUploadStatesOrganizationIdShardingKeyTrigger < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  def up
    install_sharding_key_assignment_trigger(
      table: :organization_detail_upload_states,
      sharding_key: :organization_id,
      parent_table: :organization_detail_uploads,
      parent_sharding_key: :organization_id,
      foreign_key: :organization_detail_upload_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :organization_detail_upload_states,
      sharding_key: :organization_id,
      parent_table: :organization_detail_uploads,
      parent_sharding_key: :organization_id,
      foreign_key: :organization_detail_upload_id
    )
  end
end
