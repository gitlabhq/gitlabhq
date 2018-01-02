# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveOldCircuitbreakerConfig < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    remove_column :application_settings,
                  :circuitbreaker_backoff_threshold
    remove_column :application_settings,
                  :circuitbreaker_failure_wait_time
  end

  def down
    add_column :application_settings,
               :circuitbreaker_backoff_threshold,
               :integer,
               default: 80
    add_column :application_settings,
               :circuitbreaker_failure_wait_time,
               :integer,
               default: 30
  end
end
