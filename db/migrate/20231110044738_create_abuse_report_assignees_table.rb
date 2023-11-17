# frozen_string_literal: true

class CreateAbuseReportAssigneesTable < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  INDEX_NAME = 'index_abuse_report_assignees_on_user_id_and_abuse_report_id'

  def change
    create_table :abuse_report_assignees do |t|
      t.bigint :user_id, null: false
      t.belongs_to :abuse_report,
        null: false,
        foreign_key: { to_table: :abuse_reports, on_delete: :cascade },
        index: true
      t.timestamps_with_timezone null: false
      t.index [:user_id, :abuse_report_id], unique: true, name: INDEX_NAME
    end
  end
end
