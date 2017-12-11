class AddCircuitbreakerCheckIntervalToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :application_settings,
                            :circuitbreaker_check_interval,
                            :integer,
                            default: 1
  end

  def down
    remove_column :application_settings,
                  :circuitbreaker_check_interval
  end
end
