# frozen_string_literal: true

class AddIndexToReleases < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_releases_on_released_at'

  disable_ddl_transaction!

  def up
    add_concurrent_index :releases, :released_at, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :releases, INDEX_NAME
  end
end
