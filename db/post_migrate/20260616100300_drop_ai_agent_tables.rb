# frozen_string_literal: true

class DropAiAgentTables < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  def up
    drop_table :ai_agent_versions, force: :cascade, if_exists: true
    drop_table :ai_agents, force: :cascade, if_exists: true
  end

  def down
    return if table_exists?(:ai_agents)

    create_table :ai_agents do |t|
      t.timestamps_with_timezone null: false
      t.bigint :project_id, null: false
      t.text :name, null: false

      t.check_constraint 'char_length(name) <= 255', name: 'check_67934c8e85'
    end

    add_concurrent_index :ai_agents, [:project_id, :name], unique: true,
      name: :index_ai_agents_on_project_id_and_name
    add_concurrent_foreign_key :ai_agents, :projects,
      column: :project_id, on_delete: :cascade, name: :fk_rails_3328b05449

    return if table_exists?(:ai_agent_versions)

    create_table :ai_agent_versions do |t|
      t.timestamps_with_timezone null: false
      t.bigint :project_id, null: false
      t.bigint :agent_id, null: false
      t.text :prompt, null: false
      t.text :model, null: false

      t.check_constraint 'char_length(model) <= 255', name: 'check_8cda7448e9'
      t.check_constraint 'char_length(prompt) <= 5000', name: 'check_d7a4fc9834'
    end

    add_concurrent_index :ai_agent_versions, :agent_id,
      name: :index_ai_agent_versions_on_agent_id
    add_concurrent_index :ai_agent_versions, :project_id,
      name: :index_ai_agent_versions_on_project_id
    add_concurrent_foreign_key :ai_agent_versions, :ai_agents,
      column: :agent_id, on_delete: :cascade, name: :fk_6c2f682587
    add_concurrent_foreign_key :ai_agent_versions, :projects,
      column: :project_id, on_delete: :cascade, name: :fk_rails_2205f8ca20

    # These FKs reference ai_agent_versions and are dropped by force: :cascade
    # in up. In production they are already removed by earlier migrations in
    # the chain, so this is only relevant when rolling back in isolation.
    if table_exists?(:ai_agent_version_attachments)
      add_concurrent_foreign_key :ai_agent_version_attachments, :ai_agent_versions,
        column: :ai_agent_version_id, on_delete: :cascade, name: :fk_07db0a0e5b
    end

    return unless column_exists?(:ai_conversation_messages, :agent_version_id)

    add_concurrent_foreign_key :ai_conversation_messages, :ai_agent_versions,
      column: :agent_version_id, on_delete: :nullify, name: :fk_b5d715b1e4
  end
end
