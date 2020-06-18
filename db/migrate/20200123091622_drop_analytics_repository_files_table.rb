# frozen_string_literal: true

class DropAnalyticsRepositoryFilesTable < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    # Requires ExclusiveLock on the table. Not in use, no records, no FKs.
    # rubocop:disable Migration/DropTable
    drop_table :analytics_repository_files
    # rubocop:enable Migration/DropTable
  end

  def down
    create_table :analytics_repository_files do |t|
      t.bigint :project_id, null: false
      t.string :file_path, limit: 4096, null: false
    end

    add_index :analytics_repository_files, [:project_id, :file_path], unique: true
  end
end
