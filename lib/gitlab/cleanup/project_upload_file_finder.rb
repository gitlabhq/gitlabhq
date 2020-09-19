# frozen_string_literal: true

module Gitlab
  module Cleanup
    class ProjectUploadFileFinder
      FIND_BATCH_SIZE = 500
      ABSOLUTE_UPLOAD_DIR = FileUploader.root.freeze
      EXCLUDED_SYSTEM_UPLOADS_PATH = "#{ABSOLUTE_UPLOAD_DIR}/-/*"
      EXCLUDED_HASHED_UPLOADS_PATH = "#{ABSOLUTE_UPLOAD_DIR}/@hashed/*"
      EXCLUDED_TMP_UPLOADS_PATH = "#{ABSOLUTE_UPLOAD_DIR}/tmp/*"

      # Paths are relative to the upload directory
      def each_file_batch(batch_size: FIND_BATCH_SIZE, &block)
        cmd = build_find_command(ABSOLUTE_UPLOAD_DIR)

        Open3.popen2(*cmd) do |stdin, stdout, status_thread|
          yield_paths_in_batches(stdout, batch_size, &block)

          raise "Find command failed" unless status_thread.value.success?
        end
      end

      private

      def yield_paths_in_batches(stdout, batch_size, &block)
        paths = []

        stdout.each_line("\0") do |line|
          paths << line.chomp("\0")

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
                 ! ( -path #{EXCLUDED_SYSTEM_UPLOADS_PATH} -prune )
                 ! ( -path #{EXCLUDED_HASHED_UPLOADS_PATH} -prune )
                 ! ( -path #{EXCLUDED_TMP_UPLOADS_PATH} -prune )
                 -print0]

        ionice = which_ionice
        cmd = %W[#{ionice} -c Idle] + cmd if ionice

        log_msg = "find command: \"#{cmd.join(' ')}\""
        Gitlab::AppLogger.info log_msg

        cmd
      end

      def which_ionice
        Gitlab::Utils.which('ionice')
      rescue StandardError
        # In this case, returning false is relatively safe,
        # even though it isn't very nice
        false
      end
    end
  end
end
