class EnqueueFixCrossProjectLabelLinks < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 100
  MIGRATION = 'FixCrossProjectLabelLinks'
  DELAY_INTERVAL = 5.minutes

  disable_ddl_transaction!

  class Label < ActiveRecord::Base
    self.table_name = 'labels'
  end

  class Namespace < ActiveRecord::Base
    self.table_name = 'namespaces'

    include ::EachBatch

    default_scope { where(type: 'Group', id: Label.where(type: 'GroupLabel').select('distinct group_id')) }
  end

  def up
    queue_background_migration_jobs_by_range_at_intervals(Namespace, MIGRATION, DELAY_INTERVAL, batch_size: BATCH_SIZE)
  end

  def down
    # noop
  end
end
