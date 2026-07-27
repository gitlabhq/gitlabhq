# frozen_string_literal: true

class CleanupNullSourceHostnameOnImportOfflineExports < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    # no-op - required to allow rollback of AllowNullSourceHostnameOnImportOfflineExports
  end

  def down
    execute <<~SQL
      UPDATE import_offline_exports
      SET source_hostname = COALESCE(import_offline_configurations.source_hostname, '')
      FROM import_offline_configurations
      WHERE import_offline_exports.source_hostname IS NULL
        AND import_offline_configurations.offline_export_id = import_offline_exports.id
    SQL

    execute <<~SQL
      UPDATE import_offline_exports
      SET source_hostname = ''
      WHERE source_hostname IS NULL
    SQL
  end
end
