# frozen_string_literal: true

class CreateTracesIssuesConnections < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def up
    create_table :observability_traces_issues_connections do |t|
      t.references :issue, null: false, foreign_key: { to_table: :issues, on_delete: :cascade }, index: false
      t.bigint :project_id, null: false, index: true
      t.timestamps_with_timezone null: false
      t.text :trace_identifier, null: false, limit: 128

      t.index [:issue_id, :trace_identifier],
        unique: true,
        name: 'idx_o11y_trace_issue_conn_on_issue_id_trace_identifier'
    end
  end

  def down
    drop_table :observability_traces_issues_connections
  end
end
