# frozen_string_literal: true

class CreateAgentIdentitiesTable < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  disable_ddl_transaction!

  def up
    create_table :ai_agent_identities do |t| # rubocop:disable Migration/EnsureFactoryForTable -- factory to be added in model spec
      t.bigint :user_id, null: false
      t.bigint :project_id, null: false
      t.datetime_with_timezone :revoked_at
      t.timestamps_with_timezone null: false
      t.text :agent_type, null: false, limit: 50
      t.text :machine_fingerprint, null: false, limit: 64
    end

    add_concurrent_index :ai_agent_identities,
      [:user_id, :project_id, :agent_type, :machine_fingerprint],
      unique: true,
      name: 'idx_ai_agent_identities_unique_identity'

    add_concurrent_index :ai_agent_identities,
      :project_id,
      name: 'idx_ai_agent_identities_on_project_id'

    add_concurrent_foreign_key :ai_agent_identities, :users,
      column: :user_id,
      on_delete: :cascade
  end

  def down
    drop_table :ai_agent_identities
  end
end
