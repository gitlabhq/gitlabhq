# frozen_string_literal: true

class CreateAbuseReportEvents < Gitlab::Database::Migration[2.1]
  def change
    create_table :abuse_report_events do |t|
      t.bigint :abuse_report_id, null: false, index: true
      t.bigint :user_id, index: true
      t.datetime_with_timezone :created_at, null: false
      t.integer :action, limit: 2, null: false, default: 1
      t.integer :reason, limit: 2
      t.text :comment, limit: 1024
    end
  end
end
