# frozen_string_literal: true

class AddWorkItemAgentPlansNamespaceForeignKey < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :work_item_agent_plans, :namespaces,
      column: :namespace_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :work_item_agent_plans, column: :namespace_id
    end
  end
end
