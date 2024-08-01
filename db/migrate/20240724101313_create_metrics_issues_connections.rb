# frozen_string_literal: true

class CreateMetricsIssuesConnections < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.3'

  def up
    create_table :observability_metrics_issues_connections do |t|
      t.references :issue, null: false, foreign_key: { to_table: :issues, on_delete: :cascade }, index: false
      t.bigint :namespace_id, null: false, index: true
      t.timestamps_with_timezone null: false
      t.integer :metric_type, null: false, limit: 2
      t.text :metric_name, null: false, limit: 500

      t.index [:issue_id, :metric_type, :metric_name],
        unique: true,
        name: 'idx_o11y_metric_issue_conn_on_issue_id_metric_type_name'
    end
  end

  def down
    drop_table :observability_metrics_issues_connections
  end
end
