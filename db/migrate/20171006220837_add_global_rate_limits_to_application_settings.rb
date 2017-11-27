# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddGlobalRateLimitsToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :application_settings, :throttle_unauthenticated_enabled, :boolean, default: false, allow_null: false
    add_column_with_default :application_settings, :throttle_unauthenticated_requests_per_period, :integer, default: 3600, allow_null: false
    add_column_with_default :application_settings, :throttle_unauthenticated_period_in_seconds, :integer, default: 3600, allow_null: false

    add_column_with_default :application_settings, :throttle_authenticated_api_enabled, :boolean, default: false, allow_null: false
    add_column_with_default :application_settings, :throttle_authenticated_api_requests_per_period, :integer, default: 7200, allow_null: false
    add_column_with_default :application_settings, :throttle_authenticated_api_period_in_seconds, :integer, default: 3600, allow_null: false

    add_column_with_default :application_settings, :throttle_authenticated_web_enabled, :boolean, default: false, allow_null: false
    add_column_with_default :application_settings, :throttle_authenticated_web_requests_per_period, :integer, default: 7200, allow_null: false
    add_column_with_default :application_settings, :throttle_authenticated_web_period_in_seconds, :integer, default: 3600, allow_null: false
  end

  def down
    remove_column :application_settings, :throttle_authenticated_web_period_in_seconds
    remove_column :application_settings, :throttle_authenticated_web_requests_per_period
    remove_column :application_settings, :throttle_authenticated_web_enabled

    remove_column :application_settings, :throttle_authenticated_api_period_in_seconds
    remove_column :application_settings, :throttle_authenticated_api_requests_per_period
    remove_column :application_settings, :throttle_authenticated_api_enabled

    remove_column :application_settings, :throttle_unauthenticated_period_in_seconds
    remove_column :application_settings, :throttle_unauthenticated_requests_per_period
    remove_column :application_settings, :throttle_unauthenticated_enabled
  end
end
