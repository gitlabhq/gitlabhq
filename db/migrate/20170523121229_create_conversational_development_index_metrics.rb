class CreateConversationalDevelopmentIndexMetrics < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :conversational_development_index_metrics do |t|
      t.float :leader_issues, null: false
      t.float :instance_issues, null: false
      t.string :issues_level, null: false

      t.float :leader_notes, null: false
      t.float :instance_notes, null: false
      t.string :notes_level, null: false

      t.float :leader_milestones, null: false
      t.float :instance_milestones, null: false
      t.string :milestones_level, null: false

      t.float :leader_boards, null: false
      t.float :instance_boards, null: false
      t.string :boards_level, null: false

      t.float :leader_merge_requests, null: false
      t.float :instance_merge_requests, null: false
      t.string :merge_requests_level, null: false

      t.float :leader_ci_pipelines, null: false
      t.float :instance_ci_pipelines, null: false
      t.string :ci_pipelines_level, null: false

      t.float :leader_environments, null: false
      t.float :instance_environments, null: false
      t.string :environments_level, null: false

      t.float :leader_deployments, null: false
      t.float :instance_deployments, null: false
      t.string :deployments_level, null: false

      t.float :leader_projects_prometheus_active, null: false
      t.float :instance_projects_prometheus_active, null: false
      t.string :projects_prometheus_active_level, null: false

      t.float :leader_service_desk_issues, null: false
      t.float :instance_service_desk_issues, null: false
      t.string :service_desk_issues_level, null: false

      t.timestamps null: false
    end
  end
end
