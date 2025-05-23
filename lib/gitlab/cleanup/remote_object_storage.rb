# frozen_string_literal: true

module Gitlab
  module Cleanup
    class RemoteObjectStorage
      include ::ObjectStorage::FogHelpers

      attr_reader :logger, :model_class, :storage_location_identifier

      BATCH_SIZE = 100

      def initialize(storage_location_identifier, model_class, logger: nil)
        @storage_location_identifier = storage_location_identifier
        @model_class = model_class
        @logger = logger || Gitlab::AppLogger
      end

      def run!(dry_run: true, delete: false, batch_size: BATCH_SIZE)
        unless object_store.enabled
          logger.warn Rainbow("Object storage not enabled for #{storage_location_identifier}. Skipping.").yellow
          return
        end

        if bucket_prefix.present?
          error_message = "#{storage_location_identifier} is configured with a bucket prefix '#{bucket_prefix}'.\n"
          error_message += "Unfortunately, prefixes are not supported for this Rake task.\n"
          # At the moment, Fog does not provide a cloud-agnostic way of iterating through a bucket with a prefix.
          logger.error Rainbow(error_message).red
          return
        end

        action = delete ? 'delete' : 'move to lost and found'
        dry_run_suffix = dry_run ? '. Dry run' : ''
        logger.info "Looking for orphaned remote #{storage_location_identifier} files to #{action}#{dry_run_suffix}..."

        each_orphan_file(batch_size) do |file|
          handle_orphan_file(file, dry_run: dry_run, delete: delete)
        end
      end

      private

      # Default implementation, override in specific cleaner classes if needed
      def each_orphan_file(batch_size = BATCH_SIZE)
        # we want to skip files already moved to lost_and_found directory
        lost_dir_match = "^#{lost_and_found_dir}\/"

        remote_directory.files.each_slice(batch_size) do |remote_files|
          remote_files.reject! { |file| file.key.match(/#{lost_dir_match}/) }
          file_paths = remote_files.map(&:key)
          tracked_paths = find_tracked_paths(file_paths)

          remote_files.reject! { |file| tracked_paths.include?(file.key) }
          remote_files.each do |file|
            yield file
          end
        end
      end

      # @param file_paths [Array<String>] an array of remote file paths
      # @return [Array<String>] a subset of the input paths that are tracked in the DB
      def find_tracked_paths(file_paths)
        file_paths.select do |file_path|
          file_tracked_in_the_db?(file_path)
        end
      end

      # @param file_path [String] a remote file path
      # @return [Boolean] whether or not the file is tracked in the DB. Defaults to "file is tracked" if there is any
      #   doubt, to AVOID DATA LOSS.
      def file_tracked_in_the_db?(file_path)
        # Default to "file is tracked"
        return true unless valid_file_path_format?(file_path)

        query = query_for_row_tracking_the_file(file_path)
        is_tracked = query.exists?

        log_file_tracked(file_path: file_path, is_tracked: is_tracked, query: query.to_sql)

        is_tracked
      end

      # @param args [Hash] log arguments, including at least :file_path and :is_tracked
      def log_file_tracked(**args)
        if args[:is_tracked]
          message = "Found DB record for remote stored file"
          logger.debug(args.merge(message: message))
        else
          message = "Did not find DB record for remote stored file"
          logger.info(args.merge(message: message))
        end
      end

      # @param file_path [String] a remote file path
      # @return [Boolean] true if file_path matches the expected format, false otherwise.
      def valid_file_path_format?(file_path)
        return true if file_path.match?(expected_file_path_format_regexp)

        # This can happen if we need to implement support of path formats that we were not aware of. We should increase
        # the severity of this log line after we are confident that we have accounted for all expected formats.
        logger.info(message: "Skipping because the file path doesn't match the expected format", file_path: file_path,
          expected_file_path_format_regexp: expected_file_path_format_regexp)

        false
      end

      # @abstract
      # @param file_path [String] a remote file path (the format is specific to each bucket, see the Uploader class
      # for the model being cleaned up for the expected format).
      # @return [ActiveRecord::Relation, nil] a relation that would match the corresponding row in the DB,
      #   if it exists, or nil if the file path doesn't match the expected format.
      def query_for_row_tracking_the_file(file_path)
        raise NotImplementedError
      end

      # @abstract
      # @return [Regexp] the expected file path format regexp specific to each cleaner class
      def expected_file_path_format_regexp
        raise NotImplementedError
      end

      # @param file [Fog::Storage::File] the orphan file to handle.
      # @param dry_run [Boolean] if true, only log what would be done.
      # @param delete [Boolean] if true, delete the orphan file, otherwise move it to the lost and found directory.
      # @return [void]
      def handle_orphan_file(file, dry_run:, delete:)
        msg = if dry_run
                "Would #{delete ? 'delete' : 'move to lost and found'}: #{file.key}"
              elsif delete
                file.destroy
                "Deleted: #{file.key}"
              else
                new_path = move_to_lost_and_found(file)
                "Moved to lost and found: #{file.key} -> #{new_path}"
              end

        logger.warn(msg)
      end

      def move_to_lost_and_found(file)
        new_path = "#{lost_and_found_dir}/#{file.key}"

        file.copy(object_store['remote_directory'], new_path)
        file.destroy

        new_path
      end

      def lost_and_found_dir
        'lost_and_found'
      end

      def remote_directory
        connection.directories.new(key: object_store['remote_directory'])
      end

      def bucket_prefix
        object_store.bucket_prefix
      end
    end
  end
end
