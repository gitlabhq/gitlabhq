# frozen_string_literal: true

class BackfillNamespaceIdOnDuoWorkflowSessionArtifacts < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  milestone '19.2'

  TABLE_NAME = :duo_workflow_session_artifacts

  # Backfills `namespace_id` to the project's `project_namespace_id` for project
  # rows so that `namespace_id` is populated on every row and can be used as the
  # single scoping column. The table is `table_size: small`, so a synchronous
  # batched update in a post-deployment migration is appropriate (no batched
  # background migration required).
  def up
    update_column_in_batches(
      TABLE_NAME,
      :namespace_id,
      Arel.sql(
        '(SELECT projects.project_namespace_id FROM projects ' \
          'WHERE projects.id = duo_workflow_session_artifacts.project_id)'
      )
    ) do |table, query|
      query.where(table[:project_id].not_eq(nil)).where(table[:namespace_id].eq(nil))
    end
  end

  def down
    # Project rows carried a NULL `namespace_id` under the previous exactly-one
    # sharding invariant, so nulling it for all project rows is the correct inverse.
    update_column_in_batches(TABLE_NAME, :namespace_id, nil) do |table, query|
      query.where(table[:project_id].not_eq(nil))
    end
  end
end
