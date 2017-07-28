class AddPercentagesToConvDev < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :conversational_development_index_metrics, :percentage_boards, :float
    add_column :conversational_development_index_metrics, :percentage_ci_pipelines, :float
    add_column :conversational_development_index_metrics, :percentage_deployments, :float
    add_column :conversational_development_index_metrics, :percentage_environments, :float
    add_column :conversational_development_index_metrics, :percentage_issues, :float
    add_column :conversational_development_index_metrics, :percentage_merge_requests, :float
    add_column :conversational_development_index_metrics, :percentage_milestones, :float
    add_column :conversational_development_index_metrics, :percentage_notes, :float
    add_column :conversational_development_index_metrics, :percentage_projects_prometheus_active, :float
    add_column :conversational_development_index_metrics, :percentage_service_desk_issues, :float
  end
end
