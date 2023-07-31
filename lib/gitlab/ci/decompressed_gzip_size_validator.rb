# frozen_string_literal: true

module Gitlab
  module Ci
    class DecompressedGzipSizeValidator
      DEFAULT_MAX_BYTES = 4.gigabytes.freeze
      TIMEOUT_LIMIT = 210.seconds

      ServiceError = Class.new(StandardError)

      def initialize(archive_path:, max_bytes: DEFAULT_MAX_BYTES)
        @archive_path = archive_path
        @max_bytes = max_bytes
      end

      def valid?
        validate
      end

      private

      def validate
        pgrps = nil
        valid_archive = true

        validate_archive_path

        Timeout.timeout(TIMEOUT_LIMIT) do
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

            valid_archive = false if result.to_i > max_bytes
          else
            valid_archive = false
          end

        ensure
          stdout.close
          stderr_w.close
          stderr_r.close
        end

        valid_archive
      rescue StandardError
        pgrps.each { |pgrp| Process.kill(-1, pgrp) } if pgrps

        false
      end

      def validate_archive_path
        Gitlab::PathTraversal.check_path_traversal!(archive_path)

        raise(ServiceError, 'Archive path is a symlink or hard link') if Gitlab::Utils::FileInfo.linked?(archive_path)
        raise(ServiceError, 'Archive path is not a file') unless File.file?(archive_path)
      end

      def command
        [['gzip', '-dc', archive_path], ['wc', '-c']]
      end

      attr_reader :archive_path, :max_bytes
    end
  end
end
