# frozen_string_literal: true

class CreateRemoteDevelopmentAgentConfigsTable < Gitlab::Database::Migration[2.1]
  def up
    create_table :remote_development_agent_configs do |t|
      t.timestamps_with_timezone null: false
      t.bigint :cluster_agent_id, null: false, index: true
      t.boolean :enabled, null: false
      t.text :dns_zone, null: false, limit: 256
    end
  end

  def down
    drop_table :remote_development_agent_configs
  end
end
