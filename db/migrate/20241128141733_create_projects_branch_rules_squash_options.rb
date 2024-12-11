# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateProjectsBranchRulesSquashOptions < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  PROTECTED_BRANCH_INDEX = 'index_branch_rule_squash_options_on_protected_branch_id'
  PROJECT_INDEX = 'index_project_branch_rule_squash_options_on_project_id'

  def change
    create_table :projects_branch_rules_squash_options do |t| # rubocop:disable Migration/EnsureFactoryForTable,Lint/RedundantCopDisableDirective -- See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/174192 & https://gitlab.com/gitlab-org/gitlab/-/issues/506906
      t.belongs_to :protected_branch, foreign_key: false, null: false, index: {
        unique: true, name: PROTECTED_BRANCH_INDEX
      }
      t.belongs_to :project, foreign_key: false, null: false, index: { name: PROJECT_INDEX }
      t.timestamps_with_timezone null: false
      t.column :squash_option, :smallint, default: 3, null: false
    end
  end
end
