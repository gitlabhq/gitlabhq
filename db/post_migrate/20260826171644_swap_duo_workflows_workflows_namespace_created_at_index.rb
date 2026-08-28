# frozen_string_literal: true

class SwapDuoWorkflowsWorkflowsNamespaceCreatedAtIndex < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.4'

  TABLE = :duo_workflows_workflows
  COLUMNS = [:namespace_id, :created_at].freeze
  ORDER = { created_at: :DESC }.freeze
  OLD_INDEX = 'index_duo_workflows_workflows_on_namespace_id_created_at'
  NEW_INDEX = 'index_duo_workflows_workflows_on_namespace_created_at'
  REDUNDANT_INDEX = 'index_duo_workflows_workflows_on_namespace_id'

  # The KPI now counts every definition, so the old chat-partial index no longer matches.
  # Sole consumer: PostgresqlMetricsService.
  # Partial on NOT NULL: check_73884a5839 puts project-attached rows (the vast majority)
  # at namespace_id NULL, and every reader filters or joins on namespace_id, as does
  # fk_7fcf81369f, so those entries would never be matched.
  def up
    add_concurrent_index TABLE, COLUMNS, order: ORDER, where: 'namespace_id IS NOT NULL', name: NEW_INDEX
    remove_concurrent_index_by_name TABLE, OLD_INDEX
    remove_concurrent_index_by_name TABLE, REDUNDANT_INDEX
  end

  def down
    add_concurrent_index TABLE, :namespace_id, name: REDUNDANT_INDEX
    add_concurrent_index TABLE, COLUMNS, order: ORDER, where: "workflow_definition <> 'chat'", name: OLD_INDEX
    remove_concurrent_index_by_name TABLE, NEW_INDEX
  end
end
