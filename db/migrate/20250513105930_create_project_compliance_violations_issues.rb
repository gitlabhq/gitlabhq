# frozen_string_literal: true

class CreateProjectComplianceViolationsIssues < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  def change
    create_table :project_compliance_violations_issues do |t| # rubocop:disable Migration/EnsureFactoryForTable -- https://gitlab.com/gitlab-org/gitlab/-/issues/468630
      t.bigint :project_compliance_violation_id, null: false
      t.bigint :issue_id, null: false
      t.bigint :project_id, null: false
    end
  end
end
