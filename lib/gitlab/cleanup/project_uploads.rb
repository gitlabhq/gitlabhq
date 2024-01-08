# frozen_string_literal: true

module Gitlab
  module Cleanup
    class ProjectUploads
      LOST_AND_FOUND = File.join(ProjectUploadFileFinder::ABSOLUTE_UPLOAD_DIR, '-', 'project-lost-found')

      attr_reader :logger

      def initialize(logger: nil)
        @logger = logger || Gitlab::AppLogger
      end

      def run!(dry_run: true)
        logger.info "Looking for orphaned project uploads to clean up#{'. Dry run' if dry_run}..."

        each_orphan_file do |path, upload_path|
          result = cleanup(path, upload_path, dry_run)

          logger.info result
        end
      end

      private

      def cleanup(path, upload_path, dry_run)
        # This happened in staging:
        # `find` returned a path on which `File.delete` raised `Errno::ENOENT`
        return "Cannot find file: #{path}" unless File.exist?(path)

        correct_path = upload_path && find_correct_path(upload_path)

        if correct_path
          move(path, correct_path, 'fix', dry_run)
        else
          move_to_lost_and_found(path, dry_run)
        end
      end

      # Accepts a path in the form of "#{hex_secret}/#{filename}"
      # rubocop: disable CodeReuse/ActiveRecord
      def find_correct_path(upload_path)
        upload = Upload.find_by(uploader: 'FileUploader', path: upload_path)
        return unless upload && upload.local? && upload.model

        upload.absolute_path
      rescue StandardError => e
        logger.error e.message

        # absolute_path depends on a lot of code. If it doesn't work, then it
        # it doesn't matter if the upload file is in the right place. Treat it
        # as uncorrectable.
        # I.e. the project record might be missing, which raises an exception.
        nil
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def move_to_lost_and_found(path, dry_run)
        new_path = path.sub(/\A#{ProjectUploadFileFinder::ABSOLUTE_UPLOAD_DIR}/o, LOST_AND_FOUND)

        move(path, new_path, 'move to lost and found', dry_run)
      end

      def move(path, new_path, prefix, dry_run)
        action = "#{prefix} #{path} -> #{new_path}"

        if dry_run
          "Can #{action}"
        else
          begin
            FileUtils.mkdir_p(File.dirname(new_path))
            FileUtils.mv(path, new_path)

            "Did #{action}"
          rescue StandardError => e
            "Error during #{action}: #{e.inspect}"
          end
        end
      end

      # Yields absolute paths of project upload files that are not in the
      # uploads table
      def each_orphan_file
        ProjectUploadFileFinder.new.each_file_batch do |file_paths|
          logger.debug "Processing batch of #{file_paths.size} project upload file paths, starting with #{file_paths.first}"

          file_paths.each do |path|
            pup = ProjectUploadPath.from_path(path)

            yield(path, pup.upload_path) if pup.orphan?
          end
        end
      end

      class ProjectUploadPath
        PROJECT_FULL_PATH_REGEX = %r{\A#{FileUploader.root}/(.+)/(\h+/[^/]+)\z}

        attr_reader :full_path, :upload_path

        def initialize(full_path, upload_path)
          @full_path = full_path
          @upload_path = upload_path
        end

        def self.from_path(path)
          path_matched = path.match(PROJECT_FULL_PATH_REGEX)
          return new(nil, nil) unless path_matched

          new(path_matched[1], path_matched[2])
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def orphan?
          return true if full_path.nil? || upload_path.nil?

          # It's possible to reduce to one query, but `where_full_path_in` is complex
          !Upload.exists?(path: upload_path, model_id: project_id, model_type: 'Project', uploader: 'FileUploader')
        end
        # rubocop: enable CodeReuse/ActiveRecord

        private

        # rubocop: disable CodeReuse/ActiveRecord
        def project_id
          @project_id ||= Project.where_full_path_in([full_path], preload_routes: false).pluck(:id)
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
