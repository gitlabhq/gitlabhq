# frozen_string_literal: true

class CreateGrafanaIntegrations < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    create_table :grafana_integrations do |t|
      t.references :project, index: true, foreign_key: { on_delete: :cascade }, unique: true, null: false
      t.timestamps_with_timezone null: false
      t.string :encrypted_token, limit: 255, null: false
      t.string :encrypted_token_iv, limit: 255, null: false
      t.string :grafana_url, null: false, limit: 1024
    end
  end
  # rubocop:enable Migration/PreventStrings
end
