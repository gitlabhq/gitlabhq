module Gitlab
  module BackgroundMigration
    class PopulateUntrackedUploads
      class UnhashedUploadFile < ActiveRecord::Base
        self.table_name = 'unhashed_upload_files'

        # Ends with /:random_hex/:filename
        FILE_UPLOADER_PATH_PATTERN = /\/\h+\/[^\/]+\z/

        # These regex patterns are tested against a relative path, relative to
        # the upload directory.
        # For convenience, if there exists a capture group in the pattern, then
        # it indicates the model_id.
        PATH_PATTERNS = [
          {
            pattern: /\A-\/system\/appearance\/logo\/(\d+)/,
            uploader: 'AttachmentUploader',
            model_type: 'Appearance',
          },
          {
            pattern: /\A-\/system\/appearance\/header_logo\/(\d+)/,
            uploader: 'AttachmentUploader',
            model_type: 'Appearance',
          },
          {
            pattern: /\A-\/system\/note\/attachment\/(\d+)/,
            uploader: 'AttachmentUploader',
            model_type: 'Note',
          },
          {
            pattern: /\A-\/system\/user\/avatar\/(\d+)/,
            uploader: 'AvatarUploader',
            model_type: 'User',
          },
          {
            pattern: /\A-\/system\/group\/avatar\/(\d+)/,
            uploader: 'AvatarUploader',
            model_type: 'Group',
          },
          {
            pattern: /\A-\/system\/project\/avatar\/(\d+)/,
            uploader: 'AvatarUploader',
            model_type: 'Project',
          },
          {
            pattern: FILE_UPLOADER_PATH_PATTERN,
            uploader: 'FileUploader',
            model_type: 'Project'
          },
        ]

        scope :untracked, -> { where(tracked: false) }

        def ensure_tracked!
          return if persisted? && tracked?

          unless in_uploads?
            add_to_uploads
          end

          mark_as_tracked
        end

        def in_uploads?
          # Even though we are checking relative paths, path is enough to
          # uniquely identify uploads. There is no ambiguity between
          # FileUploader paths and other Uploader paths because we use the /-/
          # separator kind of like an escape character. Project full_path will
          # never conflict with an upload path starting with "uploads/-/".
          Upload.exists?(path: upload_path)
        end

        def add_to_uploads
          Upload.create!(
            path: upload_path,
            uploader: uploader,
            model_type: model_type,
            model_id: model_id,
            size: file_size
          )
        end

        def mark_as_tracked
          self.tracked = true
          self.save!
        end

        def upload_path
          # UnhashedUploadFile#path is absolute, but Upload#path depends on uploader
          if uploader == 'FileUploader'
            # Path relative to project directory in uploads
            matchd = path_relative_to_upload_dir.match(FILE_UPLOADER_PATH_PATTERN)
            matchd[0].sub(/\A\//, '') # remove leading slash
          else
            path_relative_to_carrierwave_root
          end
        end

        def uploader
          PATH_PATTERNS.each do |path_pattern_map|
            if path_relative_to_upload_dir.match(path_pattern_map[:pattern])
              return path_pattern_map[:uploader]
            end
          end
        end

        def model_type
          PATH_PATTERNS.each do |path_pattern_map|
            if path_relative_to_upload_dir.match(path_pattern_map[:pattern])
              return path_pattern_map[:model_type]
            end
          end
        end

        def model_id
          PATH_PATTERNS.each do |path_pattern_map|
            matchd = path_relative_to_upload_dir.match(path_pattern_map[:pattern])

            # If something is captured (matchd[1] is not nil), it is a model_id
            return matchd[1] if matchd && matchd[1]
          end

          # Only the FileUploader pattern will not match an ID
          file_uploader_model_id
        end

        def file_size
          File.size(path)
        end

        # Not including a leading slash
        def path_relative_to_upload_dir
          @path_relative_to_upload_dir ||= path.sub(/\A#{Gitlab::BackgroundMigration::PrepareUnhashedUploads::UPLOAD_DIR}\//, '')
        end

        # Not including a leading slash
        def path_relative_to_carrierwave_root
          "uploads/#{path_relative_to_upload_dir}"
        end

        private

        def file_uploader_model_id
          pattern_to_capture_full_path = /\A(.+)#{FILE_UPLOADER_PATH_PATTERN}/
          matchd = path_relative_to_upload_dir.match(pattern_to_capture_full_path)
          raise "Could not capture project full_path from a FileUploader path: \"#{path_relative_to_upload_dir}\"" unless matchd
          full_path = matchd[1]
          project = Project.find_by_full_path(full_path)
          project.id.to_s
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
