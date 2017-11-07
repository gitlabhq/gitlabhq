module Gitlab
  module BackgroundMigration
    class PopulateUntrackedUploads
      class UnhashedUploadFile < ActiveRecord::Base
        self.table_name = 'unhashed_upload_files'

        scope :untracked, -> { where(tracked: false) }

        def ensure_tracked!
          # TODO
          # unless unhashed_upload_file.in_uploads?
          #   unhashed_upload_file.add_to_uploads
          # end
          #
          # unhashed_upload_file.mark_as_tracked
        end

        def model_id
          # TODO
        end

        def model_type
          # TODO
        end

        def uploader
          # TODO
        end
      end

      class Upload < ActiveRecord::Base
        self.table_name = 'uploads'
      end

      def perform(start_id, end_id)
        return unless migrate?

        files = UnhashedUploadFile.untracked.where(id: start_id..end_id)
        files.each do |unhashed_upload_file|
          unhashed_upload_file.ensure_tracked!
        end
      end

      private

      def migrate?
        UnhashedUploadFile.table_exists? && Upload.table_exists?
      end
    end
  end
end
