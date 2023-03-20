# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfill project_wiki_repositories table for a range of projects
    class BackfillProjectWikiRepositories < BatchedMigrationJob
      operation_name :backfill_project_wiki_repositories
      feature_category :geo_replication

      scope_to ->(relation) do
        relation
          .joins('LEFT OUTER JOIN project_wiki_repositories ON project_wiki_repositories.project_id = projects.id')
          .where(project_wiki_repositories: { project_id: nil })
      end

      def perform
        each_sub_batch do |sub_batch|
          backfill_project_wiki_repositories(sub_batch)
        end
      end

      def backfill_project_wiki_repositories(relation)
        connection.execute(
          <<~SQL
          INSERT INTO project_wiki_repositories (project_id, created_at, updated_at)
            SELECT projects.id, now(), now()
            FROM projects
            WHERE projects.id IN(#{relation.select(:id).to_sql})
          ON CONFLICT (project_id) DO NOTHING;
        SQL
        )
      end
    end
  end
end
