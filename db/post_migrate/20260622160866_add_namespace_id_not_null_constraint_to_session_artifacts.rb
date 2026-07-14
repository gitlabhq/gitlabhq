# frozen_string_literal: true

class AddNamespaceIdNotNullConstraintToSessionArtifacts < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  TABLE_NAME = :duo_workflow_session_artifacts

  # Enforces the new invariant that `namespace_id` is the single, always-present
  # sharding key. Runs after the backfill, so validation succeeds. The table is
  # `table_size: small`, so validating inline is acceptable.
  def up
    add_not_null_constraint(TABLE_NAME, :namespace_id)
  end

  def down
    remove_not_null_constraint(TABLE_NAME, :namespace_id)
  end
end
