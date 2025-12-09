# frozen_string_literal: true

class CreateOrganizationFoundationalAgentStatuses < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  def up
    create_table :organization_foundational_agent_statuses do |t|
      t.references :organization, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.text :reference, null: false, limit: 255
      t.boolean :enabled, null: false

      t.timestamps_with_timezone

      t.index [:organization_id, :reference],
        unique: true,
        name: 'index_ofas_organization_id_on_reference'
    end
  end

  def down
    drop_table :organization_foundational_agent_statuses
  end
end
