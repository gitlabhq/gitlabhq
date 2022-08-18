# frozen_string_literal: true

class DropQueuedAtIndexFromCiBuilds < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_ci_builds_on_queued_at'

  def up
    remove_concurrent_index_by_name :ci_builds, INDEX_NAME
  end

  # rubocop:disable Migration/PreventIndexCreation
  def down
    add_concurrent_index :ci_builds, :queued_at, name: INDEX_NAME
  end
  # rubocop:enable Migration/PreventIndexCreation
end
