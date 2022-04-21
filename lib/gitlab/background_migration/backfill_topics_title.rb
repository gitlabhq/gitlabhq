# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # The class to backfill the topic title
    class BackfillTopicsTitle
      # Temporary AR model for topics
      class Topic < ActiveRecord::Base
        self.table_name = 'topics'
      end

      def perform(start_id, end_id)
        Topic.where(id: start_id..end_id).where(title: nil).update_all('title = name')

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
