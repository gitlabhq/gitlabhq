class AddExternalClassificationAuthorizationSettingsToApplictionSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :application_settings,
                            :external_authorization_service_enabled,
                            :boolean,
                            default: false
    add_column :application_settings,
               :external_authorization_service_url,
               :string
    add_column :application_settings,
               :external_authorization_service_default_label,
               :string
  end

  def down
    remove_column :application_settings,
                  :external_authorization_service_default_label
    remove_column :application_settings,
                  :external_authorization_service_url
    remove_column :application_settings,
                  :external_authorization_service_enabled
  end
end
