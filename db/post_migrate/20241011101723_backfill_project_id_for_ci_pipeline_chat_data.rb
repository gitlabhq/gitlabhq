# frozen_string_literal: true

class BackfillProjectIdForCiPipelineChatData < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  restrict_gitlab_migration gitlab_schema: :gitlab_ci
  disable_ddl_transaction!

  TABLE_NAME = :ci_pipeline_chat_data
  BATCH_SIZE = 1_000

  def up
    model = define_batchable_model(TABLE_NAME)

    model.each_batch do |batch|
      batch
        .where("#{TABLE_NAME}.pipeline_id = p_ci_pipelines.id")
        .where("#{TABLE_NAME}.partition_id = p_ci_pipelines.partition_id")
        .update_all('project_id = p_ci_pipelines.project_id FROM p_ci_pipelines')
    end
  end

  def down
    # no-op
  end
end
