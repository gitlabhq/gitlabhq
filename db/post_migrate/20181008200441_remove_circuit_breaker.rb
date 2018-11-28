# frozen_string_literal: true

class RemoveCircuitBreaker < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  CIRCUIT_BREAKER_COLUMS_WITH_DEFAULT = {
    circuitbreaker_failure_count_threshold: 3,
    circuitbreaker_failure_reset_time: 1800,
    circuitbreaker_storage_timeout: 15,
    circuitbreaker_access_retries: 3,
    circuitbreaker_check_interval: 1
  }.freeze

  def up
    CIRCUIT_BREAKER_COLUMS_WITH_DEFAULT.keys.each do |column|
      remove_column(:application_settings, column) if column_exists?(:application_settings, column)
    end
  end

  def down
    CIRCUIT_BREAKER_COLUMS_WITH_DEFAULT.each do |column, default|
      add_column_with_default(:application_settings, column, :integer, default: default) unless column_exists?(:application_settings, column)
    end
  end
end
