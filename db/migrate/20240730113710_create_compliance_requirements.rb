# frozen_string_literal: true

class CreateComplianceRequirements < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  def change
    create_table :compliance_requirements do |t| # rubocop:disable Migration/EnsureFactoryForTable -- https://gitlab.com/gitlab-org/gitlab/-/issues/468630
      t.timestamps_with_timezone null: false
      t.bigint :framework_id, null: false
      t.bigint :namespace_id, null: false
      t.text :name, null: false, limit: 255
      t.text :description, null: false, limit: 255

      t.index :namespace_id
      t.index [:framework_id, :name], unique: true, name: 'u_compliance_requirements_for_framework'
    end
  end
end
