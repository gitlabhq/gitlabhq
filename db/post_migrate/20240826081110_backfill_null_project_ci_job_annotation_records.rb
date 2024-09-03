# frozen_string_literal: true

class BackfillNullProjectCiJobAnnotationRecords < Gitlab::Database::Migration[2.2]
  milestone '17.4'
  restrict_gitlab_migration gitlab_schema: :gitlab_ci
  disable_ddl_transaction!

  BATCH_SIZE = 1_000

  def up
    annotations_model = define_batchable_model('p_ci_job_annotations', primary_key: :id)

    annotations_model.each_batch(column: :id) do |batch|
      batch
        .where('p_ci_job_annotations.job_id = p_ci_builds.id')
        .where('p_ci_job_annotations.partition_id = p_ci_builds.partition_id')
        .update_all('project_id = p_ci_builds.project_id FROM p_ci_builds')
    end
  end

  def down
    # no-op
  end
end
