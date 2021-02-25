# frozen_string_literal: true

class ScheduleUuidPopulationForSecurityFindings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  MIGRATION_CLASS = 'PopulateUuidsForSecurityFindings'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 25

  disable_ddl_transaction!

  def up
    # no-op, replaced by 20210111075206_schedule_uuid_population_for_security_findings2.rb
  end

  def down
    # no-op
  end
end
