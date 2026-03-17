# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This BBM inserts ProjectRepository records when Projects are missing one, and fills the new records with data
    # from the project. The object_format is kept as default to avoid checking the actual repository,
    # which is acceptable because the vast majority (99.98%) of project repositories use the default value.
    class BackfillMissingProjectRepositories < BatchedMigrationJob
      cursor :id

      feature_category :geo_replication

      def perform
        each_sub_batch do |sub_batch|
          connection.execute <<~SQL
          WITH sub_batch_ids AS MATERIALIZED (#{sub_batch.select(:id).to_sql})
          INSERT INTO project_repositories (project_id, shard_id, disk_path)
          SELECT
            projects.id,
            shards.id,
            '@hashed/' ||
            substr(encode(sha256(projects.id::text::bytea), 'hex'), 1, 2) || '/' ||
            substr(encode(sha256(projects.id::text::bytea), 'hex'), 3, 2) || '/' ||
            encode(sha256(projects.id::text::bytea), 'hex')
          FROM projects
          INNER JOIN shards ON shards.name = projects.repository_storage
          LEFT JOIN project_repositories ON project_repositories.project_id = projects.id
          WHERE project_repositories.id IS NULL
            AND projects.pending_delete = FALSE
            AND projects.id IN (SELECT id FROM sub_batch_ids)
          ON CONFLICT (project_id) DO NOTHING
          SQL
        end
      end
    end
  end
end
