# frozen_string_literal: true

class CreateErrorTrackingErrorEvents < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    create_table_with_constraints :error_tracking_error_events do |t|
      t.references :error,
        index: true,
        null: false,
        foreign_key: { on_delete: :cascade, to_table: :error_tracking_errors }

      t.text :description, null: false
      t.text :environment
      t.text :level
      t.datetime_with_timezone :occurred_at, null: false
      t.jsonb :payload, null: false, default: {}

      t.text_limit :description, 255
      t.text_limit :environment, 255
      t.text_limit :level, 255

      t.timestamps_with_timezone
    end
  end

  def down
    drop_table :error_tracking_error_events
  end
end
