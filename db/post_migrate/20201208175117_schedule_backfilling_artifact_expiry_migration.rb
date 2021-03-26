# frozen_string_literal: true

class ScheduleBackfillingArtifactExpiryMigration < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  SWITCH_DATE = Time.utc(2020, 6, 22).freeze
  INDEX_NAME = 'expired_artifacts_temp_index'
  INDEX_CONDITION = "expire_at IS NULL AND created_at < '#{SWITCH_DATE}'"

  disable_ddl_transaction!

  class JobArtifact < ActiveRecord::Base
    include EachBatch

    self.table_name = 'ci_job_artifacts'

    scope :without_expiry_date, -> { where(expire_at: nil) }
    scope :before_switch, -> { where('created_at < ?', SWITCH_DATE) }
  end

  def up
    # Create temporary index for expired artifacts
    # Needs to be removed in a later migration
    add_concurrent_index(:ci_job_artifacts, %i(id created_at), where: INDEX_CONDITION, name: INDEX_NAME)

    # queue_background_migration_jobs_by_range_at_intervals(
    #   JobArtifact.without_expiry_date.before_switch,
    #   ::Gitlab::BackgroundMigration::BackfillArtifactExpiryDate,
    #   2.minutes,
    #   batch_size: 200_000
    # )
    # The scheduling code was using the full class symbol
    # (`::Gitlab::BackgroundMigration::BackfillArtifactExpiryDate`) instead of a
    # string with the class name (`BackfillArtifactExpiryDate`) by mistake,
    # which resulted in an error. It is commented out so it's a no-op to prevent
    # errors and will be reintroduced with
    # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/51822.
  end

  def down
    remove_concurrent_index_by_name :ci_job_artifacts, INDEX_NAME
  end
end
