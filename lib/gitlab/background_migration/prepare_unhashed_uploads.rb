module Gitlab
  module BackgroundMigration
    class PrepareUnhashedUploads
      FILE_PATH_BATCH_SIZE = 500
      UPLOAD_DIR = "#{CarrierWave.root}/uploads"

      class UnhashedUploadFile < ActiveRecord::Base
        self.table_name = 'unhashed_upload_files'
      end

      def perform
        return unless migrate?

        clear_unhashed_upload_file_paths
        store_unhashed_upload_file_paths
        schedule_populate_untracked_uploads_jobs
      end

      private

      def migrate?
        UnhashedUploadFile.table_exists?
      end

      def clear_unhashed_upload_file_paths
        UnhashedUploadFile.delete_all
      end

      def store_unhashed_upload_file_paths
        return unless Dir.exists?(UPLOAD_DIR)

        file_paths = []
        each_file_path(UPLOAD_DIR) do |file_path|
          file_paths << file_path

          if file_paths.size >= FILE_PATH_BATCH_SIZE
            insert_file_paths(file_paths)
            file_paths = []
          end
        end

        insert_file_paths(file_paths) if file_paths.any?
      end

      def each_file_path(search_dir, &block)
        cmd = build_find_command(search_dir)
        Open3.popen2(*cmd) do |stdin, stdout, status_thread|
          stdout.each_line("\0") do |line|
            yield(line.chomp("\0"))
          end
          raise "Find command failed" unless status_thread.value.success?
        end
      end

      def build_find_command(search_dir)
        cmd = ['find', search_dir, '-type', 'f', '!', '-path', "#{UPLOAD_DIR}/@hashed/*", '!', '-path', "#{UPLOAD_DIR}/tmp/*", '-print0']

        ['ionice', '-c', 'Idle'] + cmd if ionice_is_available?

        cmd
      end

      def ionice_is_available?
        Gitlab::Utils.which('ionice')
      rescue StandardError
        # In this case, returning false is relatively safe, even though it isn't very nice
        false
      end

      def insert_file_paths(file_paths)
        file_paths.each do |file_path|
          UnhashedUploadFile.create!(path: file_path)
        end
      end

      def schedule_populate_untracked_uploads_jobs
        # TODO
      end
    end
  end
end
