# frozen_string_literal: true

class ScheduleIssuesRootTraversalIdUpdatedAtIndex < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'idx_issues_root_namespace_updated_at'
  COLUMNS = '(namespace_traversal_ids[1]), updated_at'

  disable_ddl_transaction!
  milestone '18.6'

  # rubocop:disable Migration/PreventIndexCreation -- We already deleted indexes from that table and actively remove more
  # More to read about the introduction of traversal_ids in
  # https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/traversal_ids_on_issues/
  # TODO: Index to be created synchronously in: https://gitlab.com/gitlab-org/gitlab/-/issues/562318
  def up
    prepare_async_index :issues, COLUMNS, name: INDEX_NAME
  end
  # rubocop:enable Migration/PreventIndexCreation

  def down
    unprepare_async_index :issues, COLUMNS, name: INDEX_NAME
  end
end
