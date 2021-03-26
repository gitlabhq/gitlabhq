# frozen_string_literal: true

class ScheduleArtifactExpiryBackfill < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  MIGRATION = 'BackfillArtifactExpiryDate'
  SWITCH_DATE = Date.new(2020, 06, 22).freeze
  INDEX_NAME = 'expired_artifacts_temp_index'
  OLD_INDEX_CONDITION = "expire_at IS NULL AND created_at < '#{SWITCH_DATE}'"
  INDEX_CONDITION = "expire_at IS NULL AND date(created_at AT TIME ZONE 'UTC') < '2020-06-22'::date"

  disable_ddl_transaction!

  class JobArtifact < ActiveRecord::Base
    include EachBatch

    self.table_name = 'ci_job_artifacts'

    scope :without_expiry_date, -> { where(expire_at: nil) }
    scope :before_switch, -> { where("date(created_at AT TIME ZONE 'UTC') < ?::date", SWITCH_DATE) }
  end

  def up
    # Create temporary index for expired artifacts
    # Needs to be removed in a later migration
    remove_concurrent_index_by_name :ci_job_artifacts, INDEX_NAME
    add_concurrent_index(:ci_job_artifacts, %i(id created_at), where: INDEX_CONDITION, name: INDEX_NAME)

    queue_background_migration_jobs_by_range_at_intervals(
      JobArtifact.without_expiry_date.before_switch,
      MIGRATION,
      2.minutes,
      batch_size: 200_000
    )
  end

  def down
    remove_concurrent_index_by_name :ci_job_artifacts, INDEX_NAME
    add_concurrent_index(:ci_job_artifacts, %i(id created_at), where: OLD_INDEX_CONDITION, name: INDEX_NAME)

    Gitlab::BackgroundMigration.steal(MIGRATION) do |job|
      job.delete

      false
    end
  end
end
