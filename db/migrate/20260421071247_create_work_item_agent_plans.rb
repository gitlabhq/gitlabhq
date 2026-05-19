# frozen_string_literal: true

class CreateWorkItemAgentPlans < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def up
    create_table :work_item_agent_plans, id: false do |t| # rubocop:disable Migration/EnsureFactoryForTable -- factory in ee/spec/factories/work_items/agent_plan.rb
      t.bigint :work_item_id, primary_key: true, default: nil
      t.bigint :namespace_id, null: false

      t.timestamps_with_timezone null: false

      t.integer :cached_markdown_version
      t.integer :file_store, limit: 2, null: false, default: 1

      t.index :namespace_id
    end
  end

  def down
    drop_table :work_item_agent_plans
  end
end
