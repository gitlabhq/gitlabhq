# frozen_string_literal: true

class CreateErrorTrackingSettings < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    # rubocop:disable Migration/AddLimitToStringColumns
    create_table :project_error_tracking_settings, id: :int, primary_key: :project_id, default: nil do |t|
      t.boolean :enabled, null: false, default: true
      t.string :api_url, null: false
      t.string :encrypted_token
      t.string :encrypted_token_iv
      t.foreign_key :projects, column: :project_id, on_delete: :cascade
    end
    # rubocop:enable Migration/AddLimitToStringColumns
  end
end
