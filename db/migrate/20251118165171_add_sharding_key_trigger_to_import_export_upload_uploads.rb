# frozen_string_literal: true

class AddShardingKeyTriggerToImportExportUploadUploads < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  TABLE_NAME = :import_export_upload_uploads
  SHARDING_KEY_1 = :project_id
  SHARDING_KEY_2 = :namespace_id
  PARENT_TABLE = :import_export_uploads
  PARENT_SHARDING_KEY_1 = :project_id
  PARENT_SHARDING_KEY_2 = :group_id
  FOREIGN_KEY = :model_id

  def up
    install_sharding_key_assignment_trigger(
      table: TABLE_NAME,
      sharding_key: SHARDING_KEY_1,
      parent_table: PARENT_TABLE,
      parent_sharding_key: PARENT_SHARDING_KEY_1,
      foreign_key: FOREIGN_KEY
    )
    install_sharding_key_assignment_trigger(
      table: TABLE_NAME,
      sharding_key: SHARDING_KEY_2,
      parent_table: PARENT_TABLE,
      parent_sharding_key: PARENT_SHARDING_KEY_2,
      foreign_key: FOREIGN_KEY
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: TABLE_NAME,
      sharding_key: SHARDING_KEY_2,
      parent_table: PARENT_TABLE,
      parent_sharding_key: PARENT_SHARDING_KEY_2,
      foreign_key: FOREIGN_KEY
    )
    remove_sharding_key_assignment_trigger(
      table: TABLE_NAME,
      sharding_key: SHARDING_KEY_1,
      parent_table: PARENT_TABLE,
      parent_sharding_key: PARENT_SHARDING_KEY_1,
      foreign_key: FOREIGN_KEY
    )
  end
end
