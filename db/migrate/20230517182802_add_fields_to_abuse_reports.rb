# frozen_string_literal: true

class AddFieldsToAbuseReports < Gitlab::Database::Migration[2.1]
  RESOLVED_BY_INDEX = 'index_abuse_reports_on_resolved_by_id'
  ASSIGNEE_INDEX = 'index_abuse_reports_on_assignee_id'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :abuse_reports, :resolved_by_id, :int, null: true
      add_column :abuse_reports, :assignee_id, :int, null: true
      add_column :abuse_reports, :mitigation_steps, :text, null: true
      add_column :abuse_reports, :evidence, :jsonb, null: true
    end

    add_text_limit :abuse_reports, :mitigation_steps, 1000
    add_concurrent_index :abuse_reports, :resolved_by_id, name: RESOLVED_BY_INDEX
    add_concurrent_index :abuse_reports, :assignee_id, name: ASSIGNEE_INDEX
  end

  def down
    change_table :abuse_reports do |t|
      t.remove :resolved_by_id
      t.remove :assignee_id
      t.remove :mitigation_steps
      t.remove :evidence
    end
  end
end
