# frozen_string_literal: true

class AddGeoCacheInvalidationEventsForeignKey < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :geo_event_log, :geo_cache_invalidation_events, column: :cache_invalidation_event_id, on_delete: :cascade
    add_concurrent_index :geo_event_log, :cache_invalidation_event_id
  end

  def down
    remove_foreign_key :geo_event_log, column: :cache_invalidation_event_id
    remove_concurrent_index :geo_event_log, :cache_invalidation_event_id
  end
end
