# frozen_string_literal: true

class CreateGeoCacheInvalidationEvents < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :geo_cache_invalidation_events, id: :bigserial do |t|
      t.string :key, null: false
    end

    add_column :geo_event_log, :cache_invalidation_event_id, :integer, limit: 8
  end
end
