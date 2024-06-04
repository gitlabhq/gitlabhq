# frozen_string_literal: true

module Gitlab
  module ImportExport
    class DecompressedArchiveSizeValidator
      include Gitlab::Utils::StrongMemoize

      ServiceError = Class.new(StandardError)

      def initialize(archive_path:)
        @archive_path = archive_path
      end

      def valid?
        strong_memoize(:valid) do
          validate
        end
      end

      private

      def validate
        pgrps = nil
        valid_archive = true

        validate_archive_path

        Timeout.timeout(timeout) do
          stderr_r, stderr_w = IO.pipe
          stdout, wait_threads = Open3.pipeline_r(*command, pgroup: true, err: stderr_w)

          # When validation is performed on a small archive (e.g. 100 bytes)
          # `wait_thr` finishes before we can get process group id. Do not
          # raise exception in this scenario.
          pgrps = wait_threads.map do |wait_thr|
            Process.getpgid(wait_thr[:pid])
          rescue Errno::ESRCH
            nil
          end
          pgrps.compact!

          status = wait_threads.last.value

          if status.success?
            result = stdout.readline

            if max_bytes > 0 && result.to_i > max_bytes
              valid_archive = false

              log_error('Decompressed archive size limit reached')
            end
          else
            valid_archive = false

            log_error(stderr.readline)
          end

        ensure
          stdout.close
          stderr_w.close
          stderr_r.close
        end

        valid_archive
      rescue Timeout::Error
        log_error("Timeout of #{timeout} seconds reached during archive decompression")

        pgrps.each { |pgrp| Process.kill(-1, pgrp) } if pgrps

        false
      rescue StandardError => e
        log_error(e.message)

        pgrps.each { |pgrp| Process.kill(-1, pgrp) } if pgrps

        false
      end

      def validate_archive_path
        Gitlab::PathTraversal.check_path_traversal!(@archive_path)

        raise(ServiceError, 'Archive path is a symlink or hard link') if Gitlab::Utils::FileInfo.linked?(@archive_path)
        raise(ServiceError, 'Archive path is not a file') unless File.file?(@archive_path)
      end

      def command
        [['gzip', '-dc', @archive_path], ['wc', '-c']]
      end

      def log_error(error)
        archive_size = begin
          File.size(@archive_path)
        rescue StandardError
          nil
        end

        ::Import::Framework::Logger.info(
          message: error,
          import_upload_archive_path: @archive_path,
          import_upload_archive_size: archive_size
        )
      end

      def timeout
        Gitlab::CurrentSettings.current_application_settings.decompress_archive_file_timeout
      end

      def max_bytes
        Gitlab::CurrentSettings.current_application_settings.max_decompressed_archive_size.megabytes
      end
    end
  end
end
