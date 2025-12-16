# frozen_string_literal: true

class DropAbuseReportNotesTable < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  disable_ddl_transaction!

  def up
    drop_table :abuse_report_notes, if_exists: true
  end

  def down
    create_table :abuse_report_notes, if_not_exists: true do |t|
      t.references :abuse_report, null: false, index: true
      t.references :author, null: false, index: true
      t.references :updated_by, index: true
      t.references :resolved_by, index: true
      t.timestamps_with_timezone null: false
      t.datetime_with_timezone :resolved_at
      t.datetime_with_timezone :last_edited_at
      t.integer :cached_markdown_version
      t.text :discussion_id, limit: 255
      t.text :note, limit: 10000
      t.text :note_html, limit: 20000
      t.text :type, limit: 40
    end

    add_concurrent_foreign_key :abuse_report_notes, :abuse_reports, column: :abuse_report_id, on_delete: :cascade,
      name: 'fk_74e1990397'
    add_concurrent_foreign_key :abuse_report_notes, :users, column: :author_id, on_delete: :cascade,
      name: 'fk_44166fe70f'
    add_concurrent_foreign_key :abuse_report_notes, :users, column: :resolved_by_id, on_delete: :cascade,
      name: 'fk_57fb3e3bf2'
    add_concurrent_foreign_key :abuse_report_notes, :users, column: :updated_by_id, on_delete: :cascade,
      name: 'fk_0801b83126'
  end
end
