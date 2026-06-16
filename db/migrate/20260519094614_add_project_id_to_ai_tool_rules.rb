# frozen_string_literal: true

class AddProjectIdToAiToolRules < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.1'

  INDEX_NAME = 'idx_ai_tool_rules_ns_proj_tool_unique'
  PROJECT_ID_INDEX_NAME = 'index_ai_tool_rules_on_project_id'

  def up
    with_lock_retries do
      add_column :ai_tool_rules, :project_id, :bigint, null: true, if_not_exists: true
    end

    add_concurrent_index :ai_tool_rules, :project_id, name: PROJECT_ID_INDEX_NAME

    add_concurrent_index :ai_tool_rules,
      [:namespace_id, :project_id, :tool_name],
      unique: true,
      where: "project_id IS NOT NULL",
      name: INDEX_NAME

    add_concurrent_foreign_key :ai_tool_rules, :projects,
      column: :project_id,
      on_delete: :cascade
  end

  def down
    remove_foreign_key_if_exists :ai_tool_rules, column: :project_id
    remove_concurrent_index_by_name :ai_tool_rules, INDEX_NAME
    remove_concurrent_index_by_name :ai_tool_rules, PROJECT_ID_INDEX_NAME
    with_lock_retries do
      remove_column :ai_tool_rules, :project_id, if_exists: true
    end
  end
end
