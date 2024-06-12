# frozen_string_literal: true

class BackfillPartitionIdCiSourcesProjects < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_ci
  milestone '17.1'

  BATCH_SIZE = 100

  class CiSourcesProject < MigrationRecord
    self.table_name = 'ci_sources_projects'

    include EachBatch
  end

  def up
    CiSourcesProject.each_batch(of: BATCH_SIZE) do |batch|
      batch
        .where('ci_sources_projects.pipeline_id = ci_pipelines.id')
        .update_all('partition_id = ci_pipelines.partition_id FROM ci_pipelines')
    end
  end

  def down
    # no-op
  end
end
