# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddOpenProjectTrackerData < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    create_table :open_project_tracker_data do |t|
      t.references :service, foreign_key: { on_delete: :cascade }, type: :integer, index: true, null: false
      t.timestamps_with_timezone
      t.string :encrypted_url, limit: 255
      t.string :encrypted_url_iv, limit: 255
      t.string :encrypted_api_url, limit: 255
      t.string :encrypted_api_url_iv, limit: 255
      t.string :encrypted_token, limit: 255
      t.string :encrypted_token_iv, limit: 255
      t.string :closed_status_id, limit: 5
      t.string :project_identifier_code, limit: 100
    end
  end
  # rubocop:enable Migration/PreventStrings
end
