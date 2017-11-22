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
        ensure_temporary_tracking_table_exists

        # Since Postgres < 9.5 does not have ON CONFLICT DO NOTHING, and since
        # doing inserts-if-not-exists without ON CONFLICT DO NOTHING would be
        # slow, start with an empty table for Postgres < 9.5.
        # That way we can do bulk inserts at ~30x the speed of individual
        # inserts (~20 minutes worth of inserts at GitLab.com scale instead of
        # ~10 hours).
        # In all other cases, installations will get both bulk inserts and the
        # ability for these jobs to retry without having to clear and reinsert.
        clear_untracked_file_paths unless can_bulk_insert_and_ignore_duplicates?

        store_untracked_file_paths

        schedule_populate_untracked_uploads_jobs
      end

      private

      def ensure_temporary_tracking_table_exists
        unless UntrackedFile.connection.table_exists?(:untracked_files_for_uploads)
          UntrackedFile.connection.create_table :untracked_files_for_uploads do |t|
            t.string :path, limit: 600, null: false
            t.timestamps_with_timezone null: false
            t.index :path, unique: true
          end
        end
      end

      def clear_untracked_file_paths
        UntrackedFile.delete_all
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

        ionice = which_ionice
        cmd = %W[#{ionice} -c Idle] + cmd if ionice

        Rails.logger.info "PrepareUntrackedUploads find command: \"#{cmd.join(' ')}\""

        cmd
      end

      def which_ionice
        Gitlab::Utils.which('ionice')
      rescue StandardError
        # In this case, returning false is relatively safe, even though it isn't very nice
        false
      end

      def insert_file_paths(file_paths)
        sql = if postgresql_pre_9_5?
                "INSERT INTO #{table_columns_and_values_for_insert(file_paths)};"
              elsif postgresql?
                "INSERT INTO #{table_columns_and_values_for_insert(file_paths)} ON CONFLICT DO NOTHING;"
              else # MySQL
                "INSERT IGNORE INTO #{table_columns_and_values_for_insert(file_paths)};"
              end

        ActiveRecord::Base.connection.execute(sql)
      end

      def table_columns_and_values_for_insert(file_paths)
        values = file_paths.map do |file_path|
          ActiveRecord::Base.send(:sanitize_sql_array, ['(?, NOW(), NOW())', file_path]) # rubocop:disable GitlabSecurity/PublicSend
        end.join(', ')

        "#{UntrackedFile.table_name} (path, created_at, updated_at) VALUES #{values}"
      end

      def postgresql?
        @postgresql ||= Gitlab::Database.postgresql?
      end

      def can_bulk_insert_and_ignore_duplicates?
        !postgresql_pre_9_5?
      end

      def postgresql_pre_9_5?
        @postgresql_pre_9_5 ||= postgresql? && Gitlab::Database.version.to_f < 9.5
      end

      def schedule_populate_untracked_uploads_jobs
        bulk_queue_background_migration_jobs_by_range(UntrackedFile, FOLLOW_UP_MIGRATION)
      end
    end
  end
end
