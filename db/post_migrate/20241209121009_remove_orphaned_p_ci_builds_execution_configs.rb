# frozen_string_literal: true

class RemoveOrphanedPCiBuildsExecutionConfigs < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_ci
  milestone '17.7'

  class CiExecutionConfig < MigrationRecord
    include EachBatch

    self.table_name = :p_ci_builds_execution_configs
    self.primary_key = :id
  end

  class CiPipeline < MigrationRecord
    self.table_name = :p_ci_pipelines
    self.primary_key = :id
  end

  def up
    pipelines_query = CiPipeline
      .where('p_ci_builds_execution_configs.pipeline_id = p_ci_pipelines.id')
      .where('p_ci_builds_execution_configs.partition_id = p_ci_pipelines.partition_id')
      .select(1)

    CiExecutionConfig.each_batch do |batch|
      batch.where('NOT EXISTS (?)', pipelines_query).delete_all
    end
  end
end
