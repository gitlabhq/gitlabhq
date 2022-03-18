# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # A job to nullify duplicate ci_runners_token values in projects table in batches
    class ResetDuplicateCiRunnersTokenValuesOnProjects
      class Project < ActiveRecord::Base # rubocop:disable Style/Documentation
        include ::EachBatch

        self.table_name = 'projects'

        scope :base_query, -> do
          where.not(runners_token: nil)
        end
      end

      def perform(start_id, end_id)
        # Reset duplicate runner tokens that would prevent creating an unique index.
        duplicate_tokens = Project.base_query
          .where(id: start_id..end_id)
          .group(:runners_token)
          .having('COUNT(*) > 1')
          .pluck(:runners_token)

        Project.where(runners_token: duplicate_tokens).update_all(runners_token: nil) if duplicate_tokens.any?

        mark_job_as_succeeded(start_id, end_id)
      end

      private

      def mark_job_as_succeeded(*arguments)
        Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded('ResetDuplicateCiRunnerValuesTokensOnProjects', arguments)
      end
    end
  end
end
