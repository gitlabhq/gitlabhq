# frozen_string_literal: true

class AddImportExportUploadUploadStatesNamespaceIdShardingKeyTrigger < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def up
    install_sharding_key_assignment_trigger(
      table: :import_export_upload_upload_states,
      sharding_key: :namespace_id,
      parent_table: :import_export_upload_uploads,
      parent_sharding_key: :namespace_id,
      foreign_key: :import_export_upload_upload_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :import_export_upload_upload_states,
      sharding_key: :namespace_id,
      parent_table: :import_export_upload_uploads,
      parent_sharding_key: :namespace_id,
      foreign_key: :import_export_upload_upload_id
    )
  end
end
