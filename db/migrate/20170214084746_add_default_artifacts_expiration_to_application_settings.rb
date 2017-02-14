class AddDefaultArtifactsExpirationToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :application_settings,
      :default_artifacts_expire_in,
      :string, null: true
  end
end
