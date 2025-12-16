# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddShardingKeyTriggerToProjectImportExportRelationExportUploadUploads < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  TABLE_NAME = :project_import_export_relation_export_upload_uploads
  SHARDING_KEY = :project_id
  PARENT_TABLE = :project_relation_export_uploads
  PARENT_SHARDING_KEY = :project_id
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
