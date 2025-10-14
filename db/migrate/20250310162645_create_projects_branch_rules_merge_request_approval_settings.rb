# frozen_string_literal: true

class CreateProjectsBranchRulesMergeRequestApprovalSettings < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  PROTECTED_BRANCH_INDEX = 'idx_branch_rules_mr_approval_settings_on_protected_branch_id'
  PROJECT_INDEX = 'idx_branch_rules_mr_approval_settings_on_project_id'

  def change
    create_table :projects_branch_rules_merge_request_approval_settings do |t| # rubocop:disable Migration/EnsureFactoryForTable -- See https://gitlab.com/gitlab-org/gitlab/-/issues/504620
      t.timestamps_with_timezone null: false
      t.belongs_to :protected_branch, foreign_key: false, null: false, index: {
        unique: true, name: PROTECTED_BRANCH_INDEX
      }
      t.belongs_to :project, foreign_key: false, null: false, index: { name: PROJECT_INDEX }
      t.boolean :prevent_author_approval, default: false, null: false
      t.boolean :prevent_committer_approval, default: false, null: false
      t.boolean :prevent_editing_approval_rules, default: false, null: false
      t.boolean :require_reauthentication_to_approve, default: false, null: false
      t.integer :approval_removals, default: 1, null: false, limit: 2
    end
  end
end
