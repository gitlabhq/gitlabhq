# frozen_string_literal: true

class SwapSessionArtifactsNamespaceKeysetIndex < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  TABLE_NAME = :duo_workflow_session_artifacts
  NEW_INDEX = :index_duo_wf_session_artifacts_on_ns_wf_updated_wf_id
  OLD_INDEX = :index_duo_wf_session_artifacts_on_namespace_id_updated_at

  # Supports the keyset/in-operator query in `SessionArtifacts::PostgresqlFinder`:
  # `namespace_id IN (...) ORDER BY workflow_updated_at DESC, workflow_id DESC`.
  # The old `(namespace_id, workflow_updated_at DESC)` index is a left-prefix of
  # this one and becomes redundant (it also still backs the namespace_id FK).
  def up
    add_concurrent_index(
      TABLE_NAME,
      [:namespace_id, :workflow_updated_at, :workflow_id],
      order: { workflow_updated_at: :desc, workflow_id: :desc },
      name: NEW_INDEX
    )

    remove_concurrent_index_by_name(TABLE_NAME, OLD_INDEX)
  end

  def down
    add_concurrent_index(
      TABLE_NAME,
      [:namespace_id, :workflow_updated_at],
      order: { workflow_updated_at: :desc },
      name: OLD_INDEX
    )

    remove_concurrent_index_by_name(TABLE_NAME, NEW_INDEX)
  end
end
