# frozen_string_literal: true

class CreateLogsIssuesConnections < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def up
    create_table :observability_logs_issues_connections do |t|
      t.references :issue, null: false, foreign_key: { to_table: :issues, on_delete: :cascade }, index: false
      t.bigint :project_id, null: false, index: true
      t.datetime_with_timezone :log_timestamp, null: false
      t.timestamps_with_timezone null: false
      t.integer :severity_number, null: false, limit: 2
      t.text :service_name, null: false, limit: 500
      t.text :trace_identifier, null: false, limit: 128
      t.text :log_fingerprint, null: false, limit: 128

      t.index [:issue_id, :service_name, :severity_number, :log_timestamp, :log_fingerprint, :trace_identifier],
        unique: true,
        name: 'idx_o11y_log_issue_conn_on_issue_id_logs_search_metadata'
    end
  end

  def down
    drop_table :observability_logs_issues_connections
  end
end
