# frozen_string_literal: true

class CreateAbuseReportLabels < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def change
    create_table :abuse_report_labels do |t|
      t.timestamps_with_timezone null: false
      t.integer :cached_markdown_version
      t.text :title, limit: 255, index: { unique: true }, null: false
      t.text :color, limit: 7
      t.text :description, limit: 500
      t.text :description_html, limit: 1000
    end
  end
end
