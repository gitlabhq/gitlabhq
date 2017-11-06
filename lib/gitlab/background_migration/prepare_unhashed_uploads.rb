module Gitlab
  module BackgroundMigration
    class PrepareUnhashedUploads
      class UnhashedUploadFile < ActiveRecord::Base
        self.table_name = 'unhashed_upload_files'
      end

      def perform
        return unless migrate?

        clear_unhashed_upload_files
        store_unhashed_upload_files
        schedule_populate_untracked_uploads_jobs
      end

      private

      def migrate?
        UnhashedUploadFile.table_exists?
      end

      def clear_unhashed_upload_files
        # TODO
      end

      def store_unhashed_upload_files
        # TODO
      end

      def schedule_populate_untracked_uploads_jobs
        # TODO
      end
    end
  end
end
