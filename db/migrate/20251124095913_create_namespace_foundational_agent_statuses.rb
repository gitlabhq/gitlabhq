# frozen_string_literal: true

class CreateNamespaceFoundationalAgentStatuses < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  def up
    create_table :namespace_foundational_agent_statuses do |t|
      t.references :namespace,
        null: false,
        index: false,
        foreign_key: { on_delete: :cascade }
      t.text :reference, null: false, limit: 255
      t.boolean :enabled, null: false

      t.timestamps_with_timezone null: false

      t.index [:namespace_id, :reference],
        unique: true,
        name: 'index_nfas_on_namespaced_id_on_reference'
    end
  end

  def down
    drop_table :namespace_foundational_agent_statuses
  end
end
