class AddExternalAuthorizationServiceTimeoutToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    # We can use the regular `add_column` with a default since `application_settings`
    # is a small table.
    add_column :application_settings,
               :external_authorization_service_timeout,
               :float,
               default: 0.5
  end

  def down
    remove_column :application_settings, :external_authorization_service_timeout
  end
end
