# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # A job to create ci_project_mirrors entries in batches
    class BackfillCiProjectMirrors
      class Project < ActiveRecord::Base # rubocop:disable Style/Documentation
        include ::EachBatch

        self.table_name = 'projects'

        scope :base_query, -> do
          select(:id, :namespace_id)
        end
      end

      PAUSE_SECONDS = 0.1
      SUB_BATCH_SIZE = 500

      def perform(start_id, end_id)
        batch_query = Project.base_query.where(id: start_id..end_id)
        batch_query.each_batch(of: SUB_BATCH_SIZE) do |sub_batch|
          first, last = sub_batch.pick(Arel.sql('MIN(id), MAX(id)'))
          ranged_query = Project.unscoped.base_query.where(id: first..last)

          update_sql = <<~SQL
            INSERT INTO ci_project_mirrors (project_id, namespace_id)
            #{insert_values(ranged_query)}
            ON CONFLICT (project_id) DO NOTHING
          SQL
          # We do nothing on conflict because we consider they were already filled.

          Project.connection.execute(update_sql)

          sleep PAUSE_SECONDS
        end

        mark_job_as_succeeded(start_id, end_id)
      end

      private

      def insert_values(batch)
        batch.allow_cross_joins_across_databases(url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/336433').to_sql
      end

      def mark_job_as_succeeded(*arguments)
        Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded('BackfillCiProjectMirrors', arguments)
      end
    end
  end
end
