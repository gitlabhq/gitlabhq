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

        def to_h
          {
            path: upload_path,
            uploader: uploader,
            model_type: model_type,
            model_id: model_id,
            size: file_size,
            checksum: checksum
          }
        end

        def upload_path
          # UntrackedFile#path is absolute, but Upload#path depends on uploader
          @upload_path ||= if uploader == 'FileUploader'
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
          return @model_id if defined?(@model_id)

          matchd = path_relative_to_upload_dir.match(matching_pattern_map[:pattern])

          # If something is captured (matchd[1] is not nil), it is a model_id
          # Only the FileUploader pattern will not match an ID
          @model_id = matchd[1] ? matchd[1].to_i : file_uploader_model_id
        end

        def file_size
          File.size(absolute_path)
        end

        def checksum
          Digest::SHA256.file(absolute_path).hexdigest
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
          return nil unless project

          project.id
        end

        # Not including a leading slash
        def path_relative_to_upload_dir
          base = %r{\A#{Regexp.escape(Gitlab::BackgroundMigration::PrepareUntrackedUploads::RELATIVE_UPLOAD_DIR)}/}
          @path_relative_to_upload_dir ||= path.sub(base, '')
        end

        def absolute_path
          File.join(CarrierWave.root, path)
        end
      end

      class Upload < ActiveRecord::Base
        self.table_name = 'uploads'
      end

      def perform(start_id, end_id)
        return unless migrate?

        files = UntrackedFile.where(id: start_id..end_id)
        insert_uploads_if_needed(files)
        files.delete_all

        drop_temp_table_if_finished
      end

      private

      def migrate?
        UntrackedFile.table_exists? && Upload.table_exists?
      end

      def insert_uploads_if_needed(files)
        filtered_files = filter_existing_uploads(files)
        filtered_files = filter_deleted_models(filtered_files)
        insert(filtered_files)
      end

      def filter_existing_uploads(files)
        paths = files.map(&:upload_path)
        existing_paths = Upload.where(path: paths).pluck(:path).to_set

        files.reject do |file|
          existing_paths.include?(file.upload_path)
        end
      end

      # There are files on disk that are not in the uploads table because their
      # model was deleted, and we don't delete the files on disk.
      def filter_deleted_models(files)
        ids = deleted_model_ids(files)

        files.reject do |file|
          ids[file.model_type].include?(file.model_id)
        end
      end

      def deleted_model_ids(files)
        ids = {
          'Appearance' => [],
          'Namespace' => [],
          'Note' => [],
          'Project' => [],
          'User' => []
        }

        # group model IDs by model type
        files.each do |file|
          ids[file.model_type] << file.model_id
        end

        ids.each do |model_type, model_ids|
          found_ids = Object.const_get(model_type).where(id: model_ids.uniq).pluck(:id)
          ids[model_type] = ids[model_type] - found_ids # replace with deleted ids
        end

        ids
      end

      def insert(files)
        rows = files.map do |file|
          file.to_h.merge(created_at: 'NOW()')
        end

        Gitlab::Database.bulk_insert('uploads', rows, disable_quote: :created_at)
      end

      def drop_temp_table_if_finished
        UntrackedFile.connection.drop_table(:untracked_files_for_uploads) if UntrackedFile.all.empty?
      end
    end
  end
end
