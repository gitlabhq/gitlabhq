# frozen_string_literal: true

class AddIndexToGeoEventLog < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :geo_event_log, :container_repository_updated_event_id
  end

  def down
    remove_concurrent_index(:geo_event_log, :container_repository_updated_event_id)
  end
end
