# frozen_string_literal: true

class CreateProjectComplianceViolations < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  def change
    create_table :project_compliance_violations do |t| # rubocop:disable Migration/EnsureFactoryForTable -- https://gitlab.com/gitlab-org/gitlab/-/issues/468630
      t.timestamps_with_timezone null: false
      t.bigint :namespace_id, null: false
      t.bigint :project_id, null: false
      t.bigint :audit_event_id, null: false
      t.bigint :compliance_requirements_control_id, null: false
      t.integer :status, limit: 2, null: false
    end
  end
end
