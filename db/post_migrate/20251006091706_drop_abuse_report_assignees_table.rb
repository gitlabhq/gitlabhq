# frozen_string_literal: true

class DropAbuseReportAssigneesTable < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  def up
    drop_table :abuse_report_assignees, if_exists: true
  end

  def down
    create_table :abuse_report_assignees do |t|
      t.bigint :user_id, null: false
      t.bigint :abuse_report_id, null: false
      t.timestamps_with_timezone null: false
      t.bigint :organization_id, null: false, default: 1

      t.index :abuse_report_id, name: 'index_abuse_report_assignees_on_abuse_report_id'
      t.index :organization_id, name: 'index_abuse_report_assignees_on_organization_id'
      t.index [:user_id, :abuse_report_id], unique: true,
        name: 'index_abuse_report_assignees_on_user_id_and_abuse_report_id'
    end
  end
end
