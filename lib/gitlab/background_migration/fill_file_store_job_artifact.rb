# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class FillFileStoreJobArtifact
      class JobArtifact < ActiveRecord::Base
        self.table_name = 'ci_job_artifacts'
      end

      def perform(start_id, stop_id)
        FillFileStoreJobArtifact::JobArtifact
          .where(file_store: nil)
          .where(id: (start_id..stop_id))
          .update_all(file_store: 1)
      end
    end
  end
end
