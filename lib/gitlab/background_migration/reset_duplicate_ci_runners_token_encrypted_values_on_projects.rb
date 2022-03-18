# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # A job to nullify duplicate runners_token_encrypted values in projects table in batches
    class ResetDuplicateCiRunnersTokenEncryptedValuesOnProjects
      class Project < ActiveRecord::Base # rubocop:disable Style/Documentation
        include ::EachBatch

        self.table_name = 'projects'

        scope :base_query, -> do
          where.not(runners_token_encrypted: nil)
        end
      end

      def perform(start_id, end_id)
        # Reset duplicate runner tokens that would prevent creating an unique index.
        duplicate_tokens = Project.base_query
          .where(id: start_id..end_id)
          .group(:runners_token_encrypted)
          .having('COUNT(*) > 1')
          .pluck(:runners_token_encrypted)

        Project.where(runners_token_encrypted: duplicate_tokens).update_all(runners_token_encrypted: nil) if duplicate_tokens.any?

        mark_job_as_succeeded(start_id, end_id)
      end

      private

      def mark_job_as_succeeded(*arguments)
        Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded('ResetDuplicateCiRunnersTokenEncryptedValuesOnProjects', arguments)
      end
    end
  end
end
