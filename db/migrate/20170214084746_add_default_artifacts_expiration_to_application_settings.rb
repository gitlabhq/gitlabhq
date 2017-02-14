class AddDefaultArtifactsExpirationToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :application_settings,
      :default_artifacts_expiration,
      :integer, default: 0, null: false
  end
end
