# frozen_string_literal: true

class ScheduleBackfillPushRulesIdInProjects < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  MIGRATION = 'BackfillPushRulesIdInProjects'
  BATCH_SIZE = 1_000

  class PushRules < ActiveRecord::Base
    include EachBatch

    self.table_name = 'push_rules'
  end

  def up
    # Update one record that is connected to the instance
    value_to_be_updated_to = ScheduleBackfillPushRulesIdInProjects::PushRules.find_by(is_sample: true)&.id

    if value_to_be_updated_to
      execute "UPDATE application_settings SET push_rule_id = #{value_to_be_updated_to}
        WHERE id IN (SELECT MAX(id) FROM application_settings);"
    end

    ApplicationSetting.expire

    queue_background_migration_jobs_by_range_at_intervals(ScheduleBackfillPushRulesIdInProjects::PushRules,
                                                          MIGRATION,
                                                          5.minutes,
                                                          batch_size: BATCH_SIZE)
  end

  def down
    execute "UPDATE application_settings SET push_rule_id = NULL"

    ApplicationSetting.expire
  end
end
