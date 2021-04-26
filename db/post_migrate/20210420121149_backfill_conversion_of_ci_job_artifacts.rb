# frozen_string_literal: true

class BackfillConversionOfCiJobArtifacts < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    return unless should_run?

    backfill_conversion_of_integer_to_bigint :ci_job_artifacts, %i(id job_id), batch_size: 15000, sub_batch_size: 100
  end

  def down
    return unless should_run?

    Gitlab::Database::BackgroundMigration::BatchedMigration
      .where(job_class_name: 'CopyColumnUsingBackgroundMigrationJob')
      .where(table_name: 'ci_job_artifacts', column_name: 'id')
      .where(job_arguments: [%w[id job_id], %w[id_convert_to_bigint job_id_convert_to_bigint]].to_json)
      .delete_all
  end

  private

  def should_run?
    Gitlab.dev_or_test_env? || Gitlab.com?
  end
end
