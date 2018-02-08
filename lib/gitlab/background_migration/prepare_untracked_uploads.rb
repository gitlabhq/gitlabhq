# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This class finds all non-hashed uploaded file paths and saves them to a
    # `untracked_files_for_uploads` table.
    class PrepareUntrackedUploads # rubocop:disable Metrics/ClassLength
      # For bulk_queue_background_migration_jobs_by_range
      include Database::MigrationHelpers
      include ::Gitlab::Utils::StrongMemoize

      FIND_BATCH_SIZE = 500
      RELATIVE_UPLOAD_DIR = "uploads".freeze
      ABSOLUTE_UPLOAD_DIR = File.join(
        Gitlab.config.uploads.storage_path,
        RELATIVE_UPLOAD_DIR
      )
      FOLLOW_UP_MIGRATION = 'PopulateUntrackedUploads'.freeze
      START_WITH_ROOT_REGEX = %r{\A#{Gitlab.config.uploads.storage_path}/}
      EXCLUDED_HASHED_UPLOADS_PATH = "#{ABSOLUTE_UPLOAD_DIR}/@hashed/*".freeze
      EXCLUDED_TMP_UPLOADS_PATH = "#{ABSOLUTE_UPLOAD_DIR}/tmp/*".freeze

      # This class is used to iterate over batches of
      # `untracked_files_for_uploads` rows.
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

        if UntrackedFile.all.empty?
          drop_temp_table
        else
          schedule_populate_untracked_uploads_jobs
        end
      end

      private

      def ensure_temporary_tracking_table_exists
        table_name = :untracked_files_for_uploads
        unless UntrackedFile.connection.table_exists?(table_name)
          UntrackedFile.connection.create_table table_name do |t|
            t.string :path, limit: 600, null: false
            t.index :path, unique: true
          end
        end
      end

      def clear_untracked_file_paths
        UntrackedFile.delete_all
      end

      def store_untracked_file_paths
        return unless Dir.exist?(ABSOLUTE_UPLOAD_DIR)

        each_file_batch(ABSOLUTE_UPLOAD_DIR, FIND_BATCH_SIZE) do |file_paths|
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
          paths << line.chomp("\0").sub(START_WITH_ROOT_REGEX, '')

          if paths.size >= batch_size
            yield(paths)
            paths = []
          end
        end

        yield(paths) if paths.any?
      end

      def build_find_command(search_dir)
        cmd = %W[find -L #{search_dir}
                 -type f
                 ! ( -path #{EXCLUDED_HASHED_UPLOADS_PATH} -prune )
                 ! ( -path #{EXCLUDED_TMP_UPLOADS_PATH} -prune )
                 -print0]

        ionice = which_ionice
        cmd = %W[#{ionice} -c Idle] + cmd if ionice

        log_msg = "PrepareUntrackedUploads find command: \"#{cmd.join(' ')}\""
        Rails.logger.info log_msg

        cmd
      end

      def which_ionice
        Gitlab::Utils.which('ionice')
      rescue StandardError
        # In this case, returning false is relatively safe,
        # even though it isn't very nice
        false
      end

      def insert_file_paths(file_paths)
        sql = insert_sql(file_paths)

        ActiveRecord::Base.connection.execute(sql)
      end

      def insert_sql(file_paths)
        if postgresql_pre_9_5?
          "INSERT INTO #{table_columns_and_values_for_insert(file_paths)};"
        elsif postgresql?
          "INSERT INTO #{table_columns_and_values_for_insert(file_paths)}"\
            " ON CONFLICT DO NOTHING;"
        else # MySQL
          "INSERT IGNORE INTO"\
            " #{table_columns_and_values_for_insert(file_paths)};"
        end
      end

      def table_columns_and_values_for_insert(file_paths)
        values = file_paths.map do |file_path|
          ActiveRecord::Base.send(:sanitize_sql_array, ['(?)', file_path]) # rubocop:disable GitlabSecurity/PublicSend, Metrics/LineLength
        end.join(', ')

        "#{UntrackedFile.table_name} (path) VALUES #{values}"
      end

      def postgresql?
        strong_memoize(:postgresql) do
          Gitlab::Database.postgresql?
        end
      end

      def can_bulk_insert_and_ignore_duplicates?
        !postgresql_pre_9_5?
      end

      def postgresql_pre_9_5?
        strong_memoize(:postgresql_pre_9_5) do
          postgresql? && Gitlab::Database.version.to_f < 9.5
        end
      end

      def schedule_populate_untracked_uploads_jobs
        bulk_queue_background_migration_jobs_by_range(
          UntrackedFile, FOLLOW_UP_MIGRATION)
      end

      def drop_temp_table
        UntrackedFile.connection.drop_table(:untracked_files_for_uploads,
                                            if_exists: true)
      end
    end
  end
end
