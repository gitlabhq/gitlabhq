# frozen_string_literal: true

class CreateClusterAgents < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless table_exists?(:cluster_agents)
      with_lock_retries do
        create_table :cluster_agents do |t|
          t.timestamps_with_timezone null: false
          t.belongs_to(:project, null: false, index: true, foreign_key: { on_delete: :cascade })
          t.text :name, null: false

          t.index [:project_id, :name], unique: true
        end
      end
    end

    add_text_limit :cluster_agents, :name, 255
  end

  def down
    with_lock_retries do
      drop_table :cluster_agents
    end
  end
end
