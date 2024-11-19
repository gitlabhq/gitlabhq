# frozen_string_literal: true

class CreateAbuseReportLabelLinks < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  INDEX_NAME = 'index_abuse_report_label_links_on_report_id_and_label_id'

  def up
    create_table :abuse_report_label_links do |t|
      t.references :abuse_report, index: false, null: false, foreign_key: { on_delete: :cascade }
      t.references :abuse_report_label, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps_with_timezone null: false
    end

    add_index :abuse_report_label_links, [:abuse_report_id, :abuse_report_label_id], unique: true, name: INDEX_NAME
  end

  def down
    drop_table :abuse_report_label_links
  end
end
