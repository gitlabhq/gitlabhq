# frozen_string_literal: true

class Schedule20220328ResetDuplicateCiRunnersTokenEncryptedValuesOnProjects < Gitlab::Database::Migration[1.0]
  MIGRATION = 'ResetDuplicateCiRunnersTokenEncryptedValuesOnProjects'
  BATCH_SIZE = 2_000
  DELAY_INTERVAL = 2.minutes

  disable_ddl_transaction!

  class Project < ActiveRecord::Base # rubocop:disable Style/Documentation
    include ::EachBatch

    self.table_name = 'projects'

    scope :base_query, -> { where.not(runners_token_encrypted: nil) }
  end

  def up
    queue_background_migration_jobs_by_range_at_intervals(
      Project.base_query,
      MIGRATION,
      DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      track_jobs: true
    )
  end

  def down
    # no-op
  end
end
