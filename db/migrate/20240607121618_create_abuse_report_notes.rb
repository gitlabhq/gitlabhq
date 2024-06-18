# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateAbuseReportNotes < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def change
    create_table :abuse_report_notes do |t|
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
    end
  end
end
