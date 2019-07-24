# frozen_string_literal: true

class AddGeoContainerRepositoryUpdatedEventsTable < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :geo_container_repository_updated_events, force: :cascade do |t|
      t.integer :container_repository_id, null: false

      t.index :container_repository_id, name: :idx_geo_con_rep_updated_events_on_container_repository_id, using: :btree
    end

    add_column :geo_event_log, :container_repository_updated_event_id, :bigint
  end
end
