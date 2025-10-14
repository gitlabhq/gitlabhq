# frozen_string_literal: true

class AddConcurrentIndexToTodosOnOrganizationId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.5'

  INDEX_NAME = 'index_todos_on_organization_id'

  def up
    # NOTE: the index was prepared in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/204713
    # rubocop:disable Migration/PreventIndexCreation -- Index needed for sharding key
    add_concurrent_index :todos, :organization_id, name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_index_by_name :todos, INDEX_NAME
  end
end
