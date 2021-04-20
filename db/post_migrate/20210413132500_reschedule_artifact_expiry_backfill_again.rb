# frozen_string_literal: true

class RescheduleArtifactExpiryBackfillAgain < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  MIGRATION = 'BackfillArtifactExpiryDate'
  SWITCH_DATE = Date.new(2020, 06, 22).freeze

  disable_ddl_transaction!

  class JobArtifact < ActiveRecord::Base
    include EachBatch

    self.inheritance_column = :_type_disabled
    self.table_name = 'ci_job_artifacts'

    scope :without_expiry_date, -> { where(expire_at: nil) }
    scope :before_switch, -> { where("date(created_at AT TIME ZONE 'UTC') < ?::date", SWITCH_DATE) }
  end

  def up
    Gitlab::BackgroundMigration.steal(MIGRATION) do |job|
      job.delete

      false
    end

    queue_background_migration_jobs_by_range_at_intervals(
      JobArtifact.without_expiry_date.before_switch,
      MIGRATION,
      2.minutes,
      batch_size: 200_000
    )
  end

  def down
    Gitlab::BackgroundMigration.steal(MIGRATION) do |job|
      job.delete

      false
    end
  end
end
