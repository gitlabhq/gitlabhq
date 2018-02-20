# frozen_string_literal: true
module Gitlab
  module BackgroundMigration
    module PopulateUntrackedUploadsDependencies
      # This class is responsible for producing the attributes necessary to
      # track an uploaded file in the `uploads` table.
      class UntrackedFile < ActiveRecord::Base # rubocop:disable Metrics/ClassLength, Metrics/LineLength
        self.table_name = 'untracked_files_for_uploads'

        # Ends with /:random_hex/:filename
        FILE_UPLOADER_PATH = %r{/\h+/[^/]+\z}
        FULL_PATH_CAPTURE = /\A(.+)#{FILE_UPLOADER_PATH}/

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
            pattern: FILE_UPLOADER_PATH,
            uploader: 'FileUploader',
            model_type: 'Project'
          }
        ].freeze

        def to_h
          @upload_hash ||= {
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
          @upload_path ||=
            if uploader == 'FileUploader'
              # Path relative to project directory in uploads
              matchd = path_relative_to_upload_dir.match(FILE_UPLOADER_PATH)
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

          pattern = matching_pattern_map[:pattern]
          matchd = path_relative_to_upload_dir.match(pattern)

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

          unless @matching_pattern_map
            raise "Unknown upload path pattern \"#{path}\""
          end

          @matching_pattern_map
        end

        def file_uploader_model_id
          matchd = path_relative_to_upload_dir.match(FULL_PATH_CAPTURE)
          not_found_msg = <<~MSG
            Could not capture project full_path from a FileUploader path:
              "#{path_relative_to_upload_dir}"
          MSG
          raise not_found_msg unless matchd

          full_path = matchd[1]
          project = Gitlab::BackgroundMigration::PopulateUntrackedUploadsDependencies::Project.find_by_full_path(full_path)
          return nil unless project

          project.id
        end

        # Not including a leading slash
        def path_relative_to_upload_dir
          upload_dir = Gitlab::BackgroundMigration::PrepareUntrackedUploads::RELATIVE_UPLOAD_DIR # rubocop:disable Metrics/LineLength
          base = %r{\A#{Regexp.escape(upload_dir)}/}
          @path_relative_to_upload_dir ||= path.sub(base, '')
        end

        def absolute_path
          File.join(Gitlab.config.uploads.storage_path, path)
        end
      end

      # Avoid using application code
      class Upload < ActiveRecord::Base
        self.table_name = 'uploads'
      end

      # Avoid using application code
      class Appearance < ActiveRecord::Base
        self.table_name = 'appearances'
      end

      # Avoid using application code
      class Namespace < ActiveRecord::Base
        self.table_name = 'namespaces'
      end

      # Avoid using application code
      class Note < ActiveRecord::Base
        self.table_name = 'notes'
      end

      # Avoid using application code
      class User < ActiveRecord::Base
        self.table_name = 'users'
      end

      # Since project Markdown upload paths don't contain the project ID, we have to find the
      # project by its full_path. Due to MySQL/PostgreSQL differences, and historical reasons,
      # the logic is somewhat complex, so I've mostly copied it in here.
      class Project < ActiveRecord::Base
        self.table_name = 'projects'

        def self.find_by_full_path(path)
          binary = Gitlab::Database.mysql? ? 'BINARY' : ''
          order_sql = "(CASE WHEN #{binary} routes.path = #{connection.quote(path)} THEN 0 ELSE 1 END)"
          where_full_path_in(path).reorder(order_sql).take
        end

        def self.where_full_path_in(path)
          cast_lower = Gitlab::Database.postgresql?

          path = connection.quote(path)

          where =
            if cast_lower
              "(LOWER(routes.path) = LOWER(#{path}))"
            else
              "(routes.path = #{path})"
            end

          joins("INNER JOIN routes ON routes.source_id = projects.id AND routes.source_type = 'Project'").where(where)
        end
      end
    end
  end
end
