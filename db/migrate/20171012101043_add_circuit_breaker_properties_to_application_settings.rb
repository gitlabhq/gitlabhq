# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddCircuitBreakerPropertiesToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :application_settings,
               :circuitbreaker_failure_count_threshold,
               :integer,
               default: 160
    add_column :application_settings,
               :circuitbreaker_failure_wait_time,
               :integer,
               default: 30
    add_column :application_settings,
               :circuitbreaker_failure_reset_time,
               :integer,
               default: 1800
    add_column :application_settings,
               :circuitbreaker_storage_timeout,
               :integer,
               default: 30
  end
end
