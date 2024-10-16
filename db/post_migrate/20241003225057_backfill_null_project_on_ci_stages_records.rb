# frozen_string_literal: true

class BackfillNullProjectOnCiStagesRecords < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  restrict_gitlab_migration gitlab_schema: :gitlab_ci
  disable_ddl_transaction!

  def up
    stages_model = define_batchable_model('p_ci_stages', primary_key: :id)

    loop do
      batch = stages_model.where(project_id: nil).limit(100).to_a
      break if batch.empty?

      stages_model
        .where(id: batch.pluck(:id))
        .where('p_ci_stages.pipeline_id = p_ci_pipelines.id')
        .where('p_ci_stages.partition_id = p_ci_pipelines.partition_id')
        .update_all('project_id = p_ci_pipelines.project_id FROM p_ci_pipelines')

      stages_model
        .where(id: batch.pluck(:id))
        .where(project_id: nil)
        .delete_all
    end
  end

  def down
    # no-op
    # Not reversable
  end
end
