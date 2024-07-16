# frozen_string_literal: true

module Gitlab
  module Cleanup
    module OrphanJobArtifactFinalObjects
      class RollbackDeletedObjects
        include StorageHelpers

        UnsupportedProviderError = Class.new(StandardError)

        GOOGLE_PROVIDER = 'google'

        DEFAULT_DELETED_LIST_FILENAME = [
          ProcessList::DELETED_LIST_FILENAME_PREFIX,
          GenerateList::DEFAULT_FILENAME
        ].join.freeze

        CURSOR_TRACKER_REDIS_KEY_PREFIX = 'orphan-job-artifact-objects-cleanup-rollback-cursor-tracker--'

        def initialize(filename: nil, force_restart: false, logger: Gitlab::AppLogger)
          @force_restart = force_restart
          @logger = logger
          @filename = filename || DEFAULT_DELETED_LIST_FILENAME
          @cursor_tracker_key = build_cursor_tracker_key
        end

        def run!
          ensure_supported_provider!

          log_info("Processing #{filename}...")

          initialize_file

          each_fog_file do |fog_file|
            rollback(fog_file)
          end

          log_info("Done. Rolled back deleted objects listed in #{filename}.")
        ensure
          file&.close
        end

        private

        attr_reader :file, :filename, :force_restart, :logger, :cursor_tracker_key

        def build_cursor_tracker_key
          "#{CURSOR_TRACKER_REDIS_KEY_PREFIX}#{File.basename(filename)}"
        end

        def ensure_supported_provider!
          return if configuration.connection.provider.downcase == GOOGLE_PROVIDER

          raise UnsupportedProviderError, 'Rollback mechanism only supports Google object store provider'
        end

        def initialize_file
          @file = File.open(filename, 'r')
        end

        def each_fog_file
          cursor_position = resume_from_last_cursor_position.to_i
          file.pos = cursor_position

          file.each do |line|
            yield build_fog_file(line)

            save_current_cursor_position(file.pos)
          end

          clear_last_cursor_position
        end

        def build_fog_file(line)
          # NOTE: If the object store is configured to use bucket prefix, the ProcessList task would have included the
          # bucket_prefix in paths in the deleted objects list CSV.
          path_with_bucket_prefix, _, generation = line.split(',')
          new_fog_file(path_with_bucket_prefix, generation.strip)
        end

        def new_fog_file(key, generation)
          artifacts_directory.files.new(key: key, generation: generation)
        end

        def rollback(fog_file)
          fog_file.copy(
            fog_file.directory.key,
            fog_file.key,
            source_generation: fog_file.generation,
            if_generation_match: 0 # Makes the request fail if there is aleady a live version
          )

          log_rolled_back_object(fog_file)
        rescue Google::Apis::ClientError => error
          raise error unless error.message.include?('conditionNotMet')

          log_info("There is already a live version for object #{fog_file.key}, skipping.")
        end

        def resume_from_last_cursor_position
          if force_restart
            log_info("Force restarted. Will not resume from last known cursor position.")
            nil
          else
            get_last_cursor_position
          end
        end

        def get_last_cursor_position
          Gitlab::Redis::SharedState.with do |redis|
            position = redis.get(cursor_tracker_key)

            if position
              log_info("Resuming from last cursor position tracked in #{cursor_tracker_key}: #{position}")
            else
              log_info("No last cursor position found, starting from beginning.")
            end

            position
          end
        end

        def save_current_cursor_position(position)
          Gitlab::Redis::SharedState.with do |redis|
            # Set TTL to 1 week (86400 * 7 seconds)
            redis.set(cursor_tracker_key, position, ex: 604_800)
            log_info("Saved current cursor position: #{position}")
          end
        end

        def clear_last_cursor_position
          Gitlab::Redis::SharedState.with do |redis|
            redis.del(cursor_tracker_key)
          end
        end

        def log_rolled_back_object(fog_file)
          log_info("Rolled back deleted object #{fog_file.key} to generation #{fog_file.generation}")
        end

        def log_info(msg)
          logger.info(msg)
        end
      end
    end
  end
end
