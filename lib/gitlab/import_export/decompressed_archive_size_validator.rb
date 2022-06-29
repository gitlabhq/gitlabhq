# frozen_string_literal: true

module Gitlab
  module ImportExport
    class DecompressedArchiveSizeValidator
      include Gitlab::Utils::StrongMemoize

      DEFAULT_MAX_BYTES = 10.gigabytes.freeze
      TIMEOUT_LIMIT = 210.seconds

      ServiceError = Class.new(StandardError)

      def initialize(archive_path:, max_bytes: self.class.max_bytes)
        @archive_path = archive_path
        @max_bytes = max_bytes
      end

      def valid?
        strong_memoize(:valid) do
          validate
        end
      end

      def self.max_bytes
        DEFAULT_MAX_BYTES
      end

      private

      def validate
        pgrp = nil
        valid_archive = true

        validate_archive_path

        Timeout.timeout(TIMEOUT_LIMIT) do
          stdin, stdout, stderr, wait_thr = Open3.popen3(command, pgroup: true)
          stdin.close

          # When validation is performed on a small archive (e.g. 100 bytes)
          # `wait_thr` finishes before we can get process group id. Do not
          # raise exception in this scenario.
          pgrp = begin
            Process.getpgid(wait_thr[:pid])
          rescue Errno::ESRCH
            nil
          end

          status = wait_thr.value

          if status.success?
            result = stdout.readline

            if result.to_i > @max_bytes
              valid_archive = false

              log_error('Decompressed archive size limit reached')
            end
          else
            valid_archive = false

            log_error(stderr.readline)
          end

        ensure
          stdout.close
          stderr.close
        end

        valid_archive
      rescue Timeout::Error
        log_error('Timeout reached during archive decompression')

        Process.kill(-1, pgrp) if pgrp

        false
      rescue StandardError => e
        log_error(e.message)

        Process.kill(-1, pgrp) if pgrp

        false
      end

      def validate_archive_path
        Gitlab::Utils.check_path_traversal!(@archive_path)

        raise(ServiceError, 'Archive path is not a string') unless @archive_path.is_a?(String)
        raise(ServiceError, 'Archive path is a symlink') if File.lstat(@archive_path).symlink?
        raise(ServiceError, 'Archive path is not a file') unless File.file?(@archive_path)
      end

      def command
        "gzip -dc #{@archive_path} | wc -c"
      end

      def log_error(error)
        archive_size = begin
          File.size(@archive_path)
        rescue StandardError
          nil
        end

        Gitlab::Import::Logger.info(
          message: error,
          import_upload_archive_path: @archive_path,
          import_upload_archive_size: archive_size
        )
      end
    end
  end
end
