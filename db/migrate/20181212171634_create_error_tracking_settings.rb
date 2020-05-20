# frozen_string_literal: true

class CreateErrorTrackingSettings < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    create_table :project_error_tracking_settings, id: :int, primary_key: :project_id, default: nil do |t|
      t.boolean :enabled, null: false, default: true
      t.string :api_url, null: false
      t.string :encrypted_token
      t.string :encrypted_token_iv
      t.foreign_key :projects, column: :project_id, on_delete: :cascade
    end
  end
  # rubocop:enable Migration/PreventStrings
end
