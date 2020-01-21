# frozen_string_literal: true

class MigrateIssueTrackersData < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INTERVAL = 3.minutes.to_i
  BATCH_SIZE = 5_000
  MIGRATION = 'MigrateIssueTrackersSensitiveData'

  disable_ddl_transaction!

  class Service < ActiveRecord::Base
    self.table_name = 'services'
    self.inheritance_column = :_type_disabled

    include ::EachBatch
  end

  def up
    relation = Service.where(category: 'issue_tracker').where("properties IS NOT NULL AND properties != '{}' AND properties != ''")
    queue_background_migration_jobs_by_range_at_intervals(relation,
                                                          MIGRATION,
                                                          INTERVAL,
                                                          batch_size: BATCH_SIZE)
  end

  def down
    # no need
  end
end
