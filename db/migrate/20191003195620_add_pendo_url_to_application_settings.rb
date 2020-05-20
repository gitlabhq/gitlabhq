class AddPendoUrlToApplicationSettings < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    add_column :application_settings, :pendo_url, :string, limit: 255
  end
  # rubocop:enable Migration/PreventStrings
end
