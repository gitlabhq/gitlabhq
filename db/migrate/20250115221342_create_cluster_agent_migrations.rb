# frozen_string_literal: true

class CreateClusterAgentMigrations < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    create_table :cluster_agent_migrations do |t| # rubocop: disable Migration/EnsureFactoryForTable -- Factory exists with different path
      t.belongs_to :cluster, index: { unique: true }, null: false
      t.belongs_to :agent, null: false
      t.belongs_to :project, null: false
      t.belongs_to :issue
      t.timestamps_with_timezone null: false
      t.integer :agent_install_status, limit: 2, null: false
      t.text :agent_install_message, limit: 255
    end
  end
end
