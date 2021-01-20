# frozen_string_literal: true

class CreateAnalyticsLanguageTrendRepositoryLanguages < ActiveRecord::Migration[5.2]
  DOWNTIME = false
  INDEX_PREFIX = 'analytics_repository_languages_'

  def change
    create_table :analytics_language_trend_repository_languages, id: false do |t|
      t.integer :file_count, null: false, default: 0

      t.references :programming_language,
        null: false,
        foreign_key: { on_delete: :cascade },
        index: false
      t.references :project,
        null: false,
        foreign_key: { on_delete: :cascade },
        index: { name: INDEX_PREFIX + 'on_project_id' }
      t.integer :loc, null: false, default: 0
      t.integer :bytes, null: false, default: 0
      # Storing percentage (with 2 decimal places), on 2 bytes.
      # 50.25% => 5025
      # Max: 100.00% => 10000 (fits smallint: 32767)
      t.integer :percentage, limit: 2, null: false, default: 0
      t.date :snapshot_date, null: false
    end

    add_index :analytics_language_trend_repository_languages, %I[
      programming_language_id
      project_id
      snapshot_date
    ], name: INDEX_PREFIX + 'unique_index', unique: true
  end
end
