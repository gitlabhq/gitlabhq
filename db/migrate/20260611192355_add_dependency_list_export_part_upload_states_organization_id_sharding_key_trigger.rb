# frozen_string_literal: true

class AddDependencyListExportPartUploadStatesOrganizationIdShardingKeyTrigger < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  def up
    install_sharding_key_assignment_trigger(
      table: :dependency_list_export_part_upload_states,
      sharding_key: :organization_id,
      parent_table: :dependency_list_export_part_uploads,
      parent_sharding_key: :organization_id,
      foreign_key: :dependency_list_export_part_upload_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :dependency_list_export_part_upload_states,
      sharding_key: :organization_id,
      parent_table: :dependency_list_export_part_uploads,
      parent_sharding_key: :organization_id,
      foreign_key: :dependency_list_export_part_upload_id
    )
  end
end
