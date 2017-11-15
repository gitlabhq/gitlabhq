module Gitlab
  module BackgroundMigration
    class PrepareUntrackedUploads
      # For bulk_queue_background_migration_jobs_by_range
      include Database::MigrationHelpers

      FILE_PATH_BATCH_SIZE = 500
      RELATIVE_UPLOAD_DIR = "uploads".freeze
      ABSOLUTE_UPLOAD_DIR = "#{CarrierWave.root}/#{RELATIVE_UPLOAD_DIR}".freeze
      FOLLOW_UP_MIGRATION = 'PopulateUntrackedUploads'.freeze
      START_WITH_CARRIERWAVE_ROOT_REGEX = %r{\A#{CarrierWave.root}/}
      EXCLUDED_HASHED_UPLOADS_PATH = "#{ABSOLUTE_UPLOAD_DIR}/@hashed/*".freeze
      EXCLUDED_TMP_UPLOADS_PATH = "#{ABSOLUTE_UPLOAD_DIR}/tmp/*".freeze

      class UntrackedFile < ActiveRecord::Base
        include EachBatch

        self.table_name = 'untracked_files_for_uploads'
      end

      def perform
        return unless migrate?

        store_untracked_file_paths
        schedule_populate_untracked_uploads_jobs
      end

      private

      def migrate?
        UntrackedFile.table_exists?
      end

      def store_untracked_file_paths
        return unless Dir.exist?(ABSOLUTE_UPLOAD_DIR)

        each_file_batch(ABSOLUTE_UPLOAD_DIR, FILE_PATH_BATCH_SIZE) do |file_paths|
          insert_file_paths(file_paths)
        end
      end

      def each_file_batch(search_dir, batch_size, &block)
        cmd = build_find_command(search_dir)

        Open3.popen2(*cmd) do |stdin, stdout, status_thread|
          yield_paths_in_batches(stdout, batch_size, &block)

          raise "Find command failed" unless status_thread.value.success?
        end
      end

      def yield_paths_in_batches(stdout, batch_size, &block)
        paths = []

        stdout.each_line("\0") do |line|
          paths << line.chomp("\0").sub(START_WITH_CARRIERWAVE_ROOT_REGEX, '')

          if paths.size >= batch_size
            yield(paths)
            paths = []
          end
        end

        yield(paths)
      end

      def build_find_command(search_dir)
        cmd = %W[find #{search_dir} -type f ! ( -path #{EXCLUDED_HASHED_UPLOADS_PATH} -prune ) ! ( -path #{EXCLUDED_TMP_UPLOADS_PATH} -prune ) -print0]

        cmd = %w[ionice -c Idle] + cmd if ionice_is_available?

        cmd
      end

      def ionice_is_available?
        Gitlab::Utils.which('ionice')
      rescue StandardError
        # In this case, returning false is relatively safe, even though it isn't very nice
        false
      end

      def insert_file_paths(file_paths)
        ActiveRecord::Base.transaction do
          file_paths.each do |file_path|
            insert_file_path(file_path)
          end
        end
      end

      def insert_file_path(file_path)
        table_columns_and_values = 'untracked_files_for_uploads (path, created_at, updated_at) VALUES (?, ?, ?)'

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
        bulk_queue_background_migration_jobs_by_range(UntrackedFile, FOLLOW_UP_MIGRATION)
      end
    end
  end
end
