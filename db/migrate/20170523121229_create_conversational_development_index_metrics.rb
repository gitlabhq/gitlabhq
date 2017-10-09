# rubocop:disable Migration/Timestamps
class CreateConversationalDevelopmentIndexMetrics < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def change
    create_table :conversational_development_index_metrics do |t|
      t.float :leader_issues, null: false
      t.float :instance_issues, null: false

      t.float :leader_notes, null: false
      t.float :instance_notes, null: false

      t.float :leader_milestones, null: false
      t.float :instance_milestones, null: false

      t.float :leader_boards, null: false
      t.float :instance_boards, null: false

      t.float :leader_merge_requests, null: false
      t.float :instance_merge_requests, null: false

      t.float :leader_ci_pipelines, null: false
      t.float :instance_ci_pipelines, null: false

      t.float :leader_environments, null: false
      t.float :instance_environments, null: false

      t.float :leader_deployments, null: false
      t.float :instance_deployments, null: false

      t.float :leader_projects_prometheus_active, null: false
      t.float :instance_projects_prometheus_active, null: false

      t.float :leader_service_desk_issues, null: false
      t.float :instance_service_desk_issues, null: false

      t.timestamps null: false
    end
  end
end
