# frozen_string_literal: true

class CreateAnalyticsRepositoryFilesTable < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    create_table :analytics_repository_files do |t|
      t.references :project,
        index: false,
        foreign_key: { on_delete: :cascade },
        null: false
      t.string :file_path,
        limit: 4096,
        null: false
    end

    add_index :analytics_repository_files, [:project_id, :file_path], unique: true
  end
  # rubocop:enable Migration/PreventStrings
end
