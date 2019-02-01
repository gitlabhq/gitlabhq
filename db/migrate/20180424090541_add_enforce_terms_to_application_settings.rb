class AddEnforceTermsToApplicationSettings < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    # rubocop:disable Migration/SaferBooleanColumn
    add_column :application_settings, :enforce_terms, :boolean, default: false
  end
end
