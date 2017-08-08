class AddPercentagesToConvDev < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  DOWNTIME = false

  def up
    add_column_with_default :conversational_development_index_metrics, :percentage_boards, :float, allow_null: false, default: 0
    add_column_with_default :conversational_development_index_metrics, :percentage_ci_pipelines, :float, allow_null: false, default: 0
    add_column_with_default :conversational_development_index_metrics, :percentage_deployments, :float, allow_null: false, default: 0
    add_column_with_default :conversational_development_index_metrics, :percentage_environments, :float, allow_null: false, default: 0
    add_column_with_default :conversational_development_index_metrics, :percentage_issues, :float, allow_null: false, default: 0
    add_column_with_default :conversational_development_index_metrics, :percentage_merge_requests, :float, allow_null: false, default: 0
    add_column_with_default :conversational_development_index_metrics, :percentage_milestones, :float, allow_null: false, default: 0
    add_column_with_default :conversational_development_index_metrics, :percentage_notes, :float, allow_null: false, default: 0
    add_column_with_default :conversational_development_index_metrics, :percentage_projects_prometheus_active, :float, allow_null: false, default: 0
    add_column_with_default :conversational_development_index_metrics, :percentage_service_desk_issues, :float, allow_null: false, default: 0
  end

  def down
    remove_column :conversational_development_index_metrics, :percentage_boards
    remove_column :conversational_development_index_metrics, :percentage_ci_pipelines
    remove_column :conversational_development_index_metrics, :percentage_deployments
    remove_column :conversational_development_index_metrics, :percentage_environments
    remove_column :conversational_development_index_metrics, :percentage_issues
    remove_column :conversational_development_index_metrics, :percentage_merge_requests
    remove_column :conversational_development_index_metrics, :percentage_milestones
    remove_column :conversational_development_index_metrics, :percentage_notes
    remove_column :conversational_development_index_metrics, :percentage_projects_prometheus_active
    remove_column :conversational_development_index_metrics, :percentage_service_desk_issues
  end
end
