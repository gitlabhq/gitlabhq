# frozen_string_literal: true

class AdjustTaskNoteRenameBackgroundMigrationValues < Gitlab::Database::Migration[2.0]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  JOB_CLASS_NAME = 'RenameTaskSystemNoteToChecklistItem'
  MIGRATION_FAILED_STATUS = 4
  MIGRATION_FINISHED_STATUS = 3
  MIGRATION_ACTIVE_STATUS = 1
  JOB_FAILED_STATUS = 2

  OLD_BATCH_SIZE = 10_000
  NEW_BATCH_SIZE = 5_000

  OLD_SUB_BATCH_SIZE = 100
  NEW_SUB_BATCH_SIZE = 10

  class InlineBatchedMigration < MigrationRecord
    self.table_name = :batched_background_migrations

    scope :for_configuration, ->(job_class_name, table_name, column_name, job_arguments) do
      where(job_class_name: job_class_name, table_name: table_name, column_name: column_name)
        .where("job_arguments = ?", Gitlab::Json.dump(job_arguments)) # rubocop:disable Rails/WhereEquals
    end
  end

  class InlineBatchedJob < MigrationRecord
    include EachBatch
    self.table_name = :batched_background_migration_jobs
  end

  def up
    migration = InlineBatchedMigration.for_configuration(
      JOB_CLASS_NAME,
      :system_note_metadata,
      :id,
      []
    ).first
    return if migration.blank? || migration.status == MIGRATION_FINISHED_STATUS

    InlineBatchedJob.where(
      batched_background_migration_id: migration.id,
      status: JOB_FAILED_STATUS
    ).each_batch(of: 100) do |batch|
      batch.update_all(attempts: 0, sub_batch_size: NEW_SUB_BATCH_SIZE)
    end

    update_params = { batch_size: NEW_BATCH_SIZE, sub_batch_size: NEW_SUB_BATCH_SIZE }

    if migration.status == MIGRATION_FAILED_STATUS
      update_params[:status] = MIGRATION_ACTIVE_STATUS
      update_params[:started_at] = Time.zone.now if migration.respond_to?(:started_at)
    end

    migration.update!(**update_params)
  end

  def down
    migration = InlineBatchedMigration.for_configuration(
      JOB_CLASS_NAME,
      :system_note_metadata,
      :id,
      []
    ).first
    return if migration.blank?

    migration.update!(
      batch_size: OLD_BATCH_SIZE,
      sub_batch_size: OLD_SUB_BATCH_SIZE
    )
  end
end
