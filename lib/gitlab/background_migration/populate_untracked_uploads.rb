module Gitlab
  module BackgroundMigration
    class PopulateUntrackedUploads
      class UntrackedFile < ActiveRecord::Base
        self.table_name = 'untracked_files_for_uploads'

        # Ends with /:random_hex/:filename
        FILE_UPLOADER_PATH_PATTERN = %r{/\h+/[^/]+\z}
        FILE_UPLOADER_CAPTURE_FULL_PATH_PATTERN = %r{\A(.+)#{FILE_UPLOADER_PATH_PATTERN}}

        # These regex patterns are tested against a relative path, relative to
        # the upload directory.
        # For convenience, if there exists a capture group in the pattern, then
        # it indicates the model_id.
        PATH_PATTERNS = [
          {
            pattern: %r{\A-/system/appearance/logo/(\d+)/},
            uploader: 'AttachmentUploader',
            model_type: 'Appearance'
          },
          {
            pattern: %r{\A-/system/appearance/header_logo/(\d+)/},
            uploader: 'AttachmentUploader',
            model_type: 'Appearance'
          },
          {
            pattern: %r{\A-/system/note/attachment/(\d+)/},
            uploader: 'AttachmentUploader',
            model_type: 'Note'
          },
          {
            pattern: %r{\A-/system/user/avatar/(\d+)/},
            uploader: 'AvatarUploader',
            model_type: 'User'
          },
          {
            pattern: %r{\A-/system/group/avatar/(\d+)/},
            uploader: 'AvatarUploader',
            model_type: 'Namespace'
          },
          {
            pattern: %r{\A-/system/project/avatar/(\d+)/},
            uploader: 'AvatarUploader',
            model_type: 'Project'
          },
          {
            pattern: FILE_UPLOADER_PATH_PATTERN,
            uploader: 'FileUploader',
            model_type: 'Project'
          }
        ].freeze

        scope :untracked, -> { where(tracked: false) }

        def ensure_tracked!
          return if persisted? && tracked?

          add_to_uploads unless in_uploads?

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
          update!(tracked: true)
        end

        def upload_path
          # UntrackedFile#path is absolute, but Upload#path depends on uploader
          if uploader == 'FileUploader'
            # Path relative to project directory in uploads
            matchd = path_relative_to_upload_dir.match(FILE_UPLOADER_PATH_PATTERN)
            matchd[0].sub(%r{\A/}, '') # remove leading slash
          else
            path
          end
        end

        def uploader
          matching_pattern_map[:uploader]
        end

        def model_type
          matching_pattern_map[:model_type]
        end

        def model_id
          matchd = path_relative_to_upload_dir.match(matching_pattern_map[:pattern])

          # If something is captured (matchd[1] is not nil), it is a model_id
          return matchd[1] if matchd[1]

          # Only the FileUploader pattern will not match an ID
          file_uploader_model_id
        end

        def file_size
          absolute_path = File.join(CarrierWave.root, path)
          File.size(absolute_path)
        end

        # Not including a leading slash
        def path_relative_to_upload_dir
          base = %r{\A#{Regexp.escape(Gitlab::BackgroundMigration::PrepareUntrackedUploads::RELATIVE_UPLOAD_DIR)}/}
          @path_relative_to_upload_dir ||= path.sub(base, '')
        end

        private

        def matching_pattern_map
          @matching_pattern_map ||= PATH_PATTERNS.find do |path_pattern_map|
            path_relative_to_upload_dir.match(path_pattern_map[:pattern])
          end

          raise "Unknown upload path pattern \"#{path}\"" unless @matching_pattern_map

          @matching_pattern_map
        end

        def file_uploader_model_id
          matchd = path_relative_to_upload_dir.match(FILE_UPLOADER_CAPTURE_FULL_PATH_PATTERN)
          raise "Could not capture project full_path from a FileUploader path: \"#{path_relative_to_upload_dir}\"" unless matchd
          full_path = matchd[1]
          project = Project.find_by_full_path(full_path)
          project.id.to_s
        end
      end

      # Copy-pasted class for less fragile migration
      class Upload < ActiveRecord::Base
        self.table_name = 'uploads' # This is the only line different from copy-paste

        # Upper limit for foreground checksum processing
        CHECKSUM_THRESHOLD = 100.megabytes

        belongs_to :model, polymorphic: true # rubocop:disable Cop/PolymorphicAssociations

        before_save  :calculate_checksum, if:     :foreground_checksum?
        after_commit :schedule_checksum,  unless: :foreground_checksum?

        def absolute_path
          return path unless relative_path?

          uploader_class.absolute_path(self)
        end

        def calculate_checksum
          return unless exist?

          self.checksum = Digest::SHA256.file(absolute_path).hexdigest
        end

        def exist?
          File.exist?(absolute_path)
        end

        private

        def foreground_checksum?
          size <= CHECKSUM_THRESHOLD
        end

        def schedule_checksum
          UploadChecksumWorker.perform_async(id)
        end

        def relative_path?
          !path.start_with?('/')
        end

        def uploader_class
          Object.const_get(uploader)
        end
      end

      def perform(start_id, end_id)
        return unless migrate?

        files = UntrackedFile.untracked.where(id: start_id..end_id)
        files.each do |untracked_file|
          begin
            untracked_file.ensure_tracked!
          rescue StandardError => e
            Rails.logger.warn "Failed to add untracked file to uploads: #{e.message}"

            # The untracked rows will remain in the DB. We will be able to see
            # which ones failed to become tracked, and then we can decide what
            # to do.
          end
        end
      end

      private

      def migrate?
        UntrackedFile.table_exists? && Upload.table_exists?
      end
    end
  end
end
