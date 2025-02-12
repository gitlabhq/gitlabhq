# frozen_string_literal: true

class CreateMergeRequestsApprovalRulesProjects < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    create_table :merge_requests_approval_rules_projects do |t| # -- Migration/EnsureFactoryForTable false positive
      t.bigint :approval_rule_id, null: false
      t.bigint :project_id, null: false
      t.index :project_id, name: 'index_mrs_approval_rules_projects_on_project_id'
      t.timestamps_with_timezone null: false
    end

    add_index(
      :merge_requests_approval_rules_projects,
      %i[approval_rule_id project_id],
      unique: true,
      name: 'index_mrs_ars_projects_on_ar_id_and_project_id'
    )
  end
end
