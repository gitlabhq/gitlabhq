# frozen_string_literal: true

class ReplaceAiToolRulesNamespaceIndexWithPartial < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.1'

  OLD_INDEX_NAME = 'idx_ai_tool_rules_ns_tool_unique'
  OLD_PROJ_INDEX_NAME = 'idx_ai_tool_rules_ns_proj_tool_unique'
  NEW_INDEX_NAME = 'idx_ai_tool_rules_ns_proj_tool_unique'

  def up
    remove_concurrent_index_by_name :ai_tool_rules, OLD_INDEX_NAME
    remove_concurrent_index_by_name :ai_tool_rules, OLD_PROJ_INDEX_NAME

    add_concurrent_index :ai_tool_rules,
      [:namespace_id, :project_id, :tool_name],
      unique: true,
      nulls_not_distinct: true,
      name: NEW_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ai_tool_rules, NEW_INDEX_NAME

    add_concurrent_index :ai_tool_rules,
      [:namespace_id, :tool_name],
      unique: true,
      name: OLD_INDEX_NAME

    add_concurrent_index :ai_tool_rules,
      [:namespace_id, :project_id, :tool_name],
      unique: true,
      where: "project_id IS NOT NULL",
      name: OLD_PROJ_INDEX_NAME
  end
end
