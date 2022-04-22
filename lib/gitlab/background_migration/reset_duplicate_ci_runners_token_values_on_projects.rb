# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # A job to nullify duplicate ci_runners_token values in projects table in batches
    class ResetDuplicateCiRunnersTokenValuesOnProjects
      class Project < ActiveRecord::Base # rubocop:disable Style/Documentation
        include EachBatch

        self.table_name = 'projects'

        scope :base_query, -> { where.not(runners_token: nil) }
      end

      def perform(start_id, end_id)
        # Reset duplicate runner tokens that would prevent creating an unique index.
        batch_records = Project.base_query.where(id: start_id..end_id)

        duplicate_tokens = Project.base_query
          .where(runners_token: batch_records.select(:runners_token).distinct)
          .group(:runners_token)
          .having('COUNT(*) > 1')
          .pluck(:runners_token)

        batch_records.where(runners_token: duplicate_tokens).update_all(runners_token: nil) if duplicate_tokens.any?

        mark_job_as_succeeded(start_id, end_id)
      end

      private

      def mark_job_as_succeeded(*arguments)
        ::Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded(
          self.class.name.demodulize,
          arguments
        )
      end
    end
  end
end
