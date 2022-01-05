# frozen_string_literal: true

class BackfillIncidentIssueEscalationStatuses < Gitlab::Database::Migration[1.0]
  MIGRATION = 'BackfillIncidentIssueEscalationStatuses'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 20_000

  disable_ddl_transaction!

  class Issue < ActiveRecord::Base
    include EachBatch

    self.table_name = 'issues'
  end

  def up
    relation = Issue.all

    queue_background_migration_jobs_by_range_at_intervals(
      relation, MIGRATION, DELAY_INTERVAL, batch_size: BATCH_SIZE, track_jobs: true)
  end

  def down
    # no-op
  end
end
