class AddEnforceTermsToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :application_settings, :enforce_terms, :boolean, default: false
  end
end
