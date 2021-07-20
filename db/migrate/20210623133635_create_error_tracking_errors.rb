# frozen_string_literal: true

class CreateErrorTrackingErrors < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    create_table_with_constraints :error_tracking_errors do |t|
      t.references :project, index: true, null: false, foreign_key: { on_delete: :cascade }
      t.text :name, null: false
      t.text :description, null: false
      t.text :actor, null: false
      t.datetime_with_timezone :first_seen_at, null: false, default: -> { 'NOW()' }
      t.datetime_with_timezone :last_seen_at, null: false, default: -> { 'NOW()' }
      t.text :platform

      t.text_limit :name, 255
      t.text_limit :description, 1024
      t.text_limit :actor, 255
      t.text_limit :platform, 255

      t.timestamps_with_timezone
    end
  end

  def down
    drop_table :error_tracking_errors
  end
end
