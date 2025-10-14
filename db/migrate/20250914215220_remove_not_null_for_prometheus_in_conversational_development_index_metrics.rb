# frozen_string_literal: true

class RemoveNotNullForPrometheusInConversationalDevelopmentIndexMetrics < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.5'

  def up
    change_column_null :conversational_development_index_metrics, :leader_projects_prometheus_active, true
    change_column_null :conversational_development_index_metrics, :instance_projects_prometheus_active, true
  end

  def down
    change_column_null :conversational_development_index_metrics, :leader_projects_prometheus_active, false
    change_column_null :conversational_development_index_metrics, :instance_projects_prometheus_active, false
  end
end
