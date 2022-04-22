# frozen_string_literal: true

class DeleteFailedResetDuplicateCiRunnersTokenMigrationRecords < Gitlab::Database::Migration[1.0]
  def up
    # Delete remaining records of botched migrations before we start the new migrations
    Gitlab::Database::BackgroundMigrationJob
      .for_migration_class('ResetDuplicateCiRunnersTokenValuesOnProjects')
      .delete_all
    Gitlab::Database::BackgroundMigrationJob
      .for_migration_class('ResetDuplicateCiRunnersTokenEncryptedValuesOnProjects')
      .delete_all
  end

  def down
    # no-op
  end
end
