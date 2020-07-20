# frozen_string_literal: true

class CreateClusterAgentTokens < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless table_exists?(:cluster_agent_tokens)
      create_table :cluster_agent_tokens do |t|
        t.timestamps_with_timezone null: false
        t.belongs_to :agent, null: false, index: true, foreign_key: { to_table: :cluster_agents, on_delete: :cascade }
        t.text :token_encrypted, null: false

        t.index :token_encrypted, unique: true
      end
    end

    add_text_limit :cluster_agent_tokens, :token_encrypted, 255
  end

  def down
    drop_table :cluster_agent_tokens
  end
end
