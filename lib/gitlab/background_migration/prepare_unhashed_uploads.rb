module Gitlab
  module BackgroundMigration
    class PrepareUnhashedUploads
      # For bulk_queue_background_migration_jobs_by_range
      include Database::MigrationHelpers

      FILE_PATH_BATCH_SIZE = 500
      UPLOAD_DIR = "#{CarrierWave.root}/uploads".freeze
      FOLLOW_UP_MIGRATION = 'PopulateUntrackedUploads'.freeze

      class UnhashedUploadFile < ActiveRecord::Base
        include EachBatch

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
        return unless Dir.exist?(UPLOAD_DIR)

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
        hashed_path = "#{UPLOAD_DIR}/@hashed/*"
        tmp_path = "#{UPLOAD_DIR}/tmp/*"
        cmd = %W[find #{search_dir} -type f ! ( -path #{hashed_path} -prune ) ! ( -path #{tmp_path} -prune ) -print0]

        %w[ionice -c Idle] + cmd if ionice_is_available?

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
          insert_file_path(file_path)
        end
      end

      def insert_file_path(file_path)
        table_columns_and_values = 'unhashed_upload_files (path, created_at, updated_at) VALUES (?, ?, ?)'

        sql = if Gitlab::Database.postgresql?
          "INSERT INTO #{table_columns_and_values} ON CONFLICT DO NOTHING;"
        else
          "INSERT IGNORE INTO #{table_columns_and_values};"
        end

        timestamp = Time.now.utc.iso8601
        sql = ActiveRecord::Base.send(:sanitize_sql_array, [sql, file_path, timestamp, timestamp])
        ActiveRecord::Base.connection.execute(sql)
      end

      def schedule_populate_untracked_uploads_jobs
        bulk_queue_background_migration_jobs_by_range(UnhashedUploadFile, FOLLOW_UP_MIGRATION)
      end
    end
  end
end
