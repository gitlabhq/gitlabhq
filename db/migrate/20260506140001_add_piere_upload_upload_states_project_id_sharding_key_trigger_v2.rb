# frozen_string_literal: true

class AddPiereUploadUploadStatesProjectIdShardingKeyTriggerV2 < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def up
    install_sharding_key_assignment_trigger(
      table: :project_import_export_relation_export_upload_upload_states,
      sharding_key: :project_id,
      parent_table: :project_import_export_relation_export_upload_uploads,
      parent_sharding_key: :project_id,
      foreign_key: :project_import_export_relation_export_upload_upload_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :project_import_export_relation_export_upload_upload_states,
      sharding_key: :project_id,
      parent_table: :project_import_export_relation_export_upload_uploads,
      parent_sharding_key: :project_id,
      foreign_key: :project_import_export_relation_export_upload_upload_id
    )
  end
end
