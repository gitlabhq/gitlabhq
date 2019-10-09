# frozen_string_literal: true

class DropUnusedAnalyticsRepositoryFileEdits < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def up
    # The table was never used, there is no app code that writes or reads the table. Safe to remove.
    drop_table :analytics_repository_file_edits
  end

  def down
    create_table :analytics_repository_file_edits do |t|
      t.references :project,
        index: true,
        foreign_key: { on_delete: :cascade }, null: false
      t.references :analytics_repository_file,
        index: false,
        foreign_key: { on_delete: :cascade },
        null: false
      t.date :committed_date,
        null: false
      t.integer :num_edits,
        null: false,
        default: 0
    end

    add_index :analytics_repository_file_edits,
      [:analytics_repository_file_id, :committed_date, :project_id],
      name: 'index_file_edits_on_committed_date_file_id_and_project_id',
      unique: true
  end
end
