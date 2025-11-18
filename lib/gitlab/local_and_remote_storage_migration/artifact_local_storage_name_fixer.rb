# frozen_string_literal: true

module Gitlab
  module LocalAndRemoteStorageMigration
    class ArtifactLocalStorageNameFixer
      def initialize(logger = nil)
        @logger = logger
      end

      def rename_artifacts
        logger.info('Starting renaming process in local storage')
        items_with_files_stored_locally.each_batch(of: batch_size) do |batch|
          batch.each do |item|
            log_success(item) if FilePathFixer.fix_file_path!(item)
          rescue NoMethodError, ArgumentError, Errno::ENOENT, Errno::EACCES, Errno::ENOTDIR, Errno::EEXIST, IOError => e
            log_error(e, item)
          end
        end
      end

      private

      attr_reader :logger

      def batch_size
        ENV.fetch('MIGRATION_BATCH_SIZE', 10).to_i
      end

      def log_success(item)
        logger.info("Renamed #{item.class.name} ID #{item.id} with size #{item.size}.")
      end

      def log_error(err, item)
        logger.warn("Failed to rename #{item.class.name} ID #{item.id} with error: #{err.message}.")
      end

      def items_with_files_stored_locally
        ::Ci::JobArtifact.with_files_stored_locally
      end
    end
  end
end
