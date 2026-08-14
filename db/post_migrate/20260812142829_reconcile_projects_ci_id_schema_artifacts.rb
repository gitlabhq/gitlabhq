# frozen_string_literal: true

class ReconcileProjectsCiIdSchemaArtifacts < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  disable_ddl_transaction!

  INDEX_NAME = 'index_projects_on_ci_id'
  TABLE_NAME = :projects

  def up
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)

    # No ignore_column is needed: projects.ci_id is absent from db/structure.sql and from
    # all canonical/production installations. This migration only removes the column on
    # environments (e.g. staging) that carry schema drift from the original migration
    # 20190424134256 not having been applied. The column has no application references.
    with_lock_retries do
      remove_column(TABLE_NAME, :ci_id, if_exists: true)
    end
  end

  def down
    # no-op: this migration reconciles schema drift on staging where the column
    # and index were never removed by the original migration 20190424134256.
    # Re-introducing them would re-create the drift we are fixing.
  end
end
