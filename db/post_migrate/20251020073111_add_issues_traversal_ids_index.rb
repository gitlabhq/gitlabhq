# frozen_string_literal: true

class AddIssuesTraversalIdsIndex < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'idx_issues_state_id_namespace_traversal_ids'
  COLUMNS = %i[state_id namespace_traversal_ids]

  disable_ddl_transaction!

  milestone '18.6'

  # rubocop:disable Migration/PreventIndexCreation -- We already deleted indexes from that table and actively remove more
  # More to read about the introduction of traversal_ids in
  # https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/traversal_ids_on_issues/
  def up
    add_concurrent_index :issues, COLUMNS, name: INDEX_NAME
  end
  # rubocop:enable Migration/PreventIndexCreation

  def down
    remove_concurrent_index :issues, COLUMNS, name: INDEX_NAME
  end
end
