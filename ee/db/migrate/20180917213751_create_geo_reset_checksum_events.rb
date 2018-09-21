# frozen_string_literal: true

class CreateGeoResetChecksumEvents < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :geo_reset_checksum_events, id: :bigserial do |t|
      t.references :project, index: true, foreign_key: { on_delete: :cascade }, null: false
    end

    add_column :geo_event_log, :reset_checksum_event_id, :integer, limit: 8
  end
end
