# frozen_string_literal: true

class PrepareAsyncIndexToTodosOnOrganizationId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.5'

  INDEX_NAME = 'index_todos_on_organization_id'

  def up
    # rubocop:disable Migration/PreventIndexCreation -- needed for sharding key
    prepare_async_index :todos, :organization_id, name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    unprepare_async_index :todos, INDEX_NAME
  end
end
