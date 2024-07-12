# frozen_string_literal: true

module Gitlab
  module Cleanup
    module OrphanJobArtifactFinalObjects
      class ProcessList
        BATCH_SIZE = Rails.env.development? ? 5 : 1000
        DELETED_LIST_FILENAME_PREFIX = 'deleted_from--'
        CURSOR_TRACKER_REDIS_KEY_PREFIX = 'orphan-job-artifact-objects-cleanup-cursor-tracker--'

        def initialize(filename: nil, force_restart: false, logger: Gitlab::AppLogger)
          @force_restart = force_restart
          @logger = logger
          @orphan_list_filename = filename || GenerateList::DEFAULT_FILENAME
          @deleted_list_filename = build_deleted_list_filename
          @cursor_tracker_key = build_cursor_tracker_key
        end

        def run!
          log_info("Processing #{orphan_list_filename}...")

          initialize_files

          each_batch do |entries|
            orphans_from_batch(entries).each do |fog_file|
              delete_orphan_object(fog_file)
            end
          end

          log_info("Done. All deleted objects are listed in #{deleted_list_filename}.")
        ensure
          orphan_list_file&.close
          deleted_list_file&.close
        end

        private

        attr_reader :orphan_list_file, :orphan_list_filename,
          :deleted_list_file, :deleted_list_filename,
          :cursor_tracker_key, :force_restart, :logger

        def build_deleted_list_filename
          dirname = File.dirname(orphan_list_filename)
          basename = "#{DELETED_LIST_FILENAME_PREFIX}#{File.basename(orphan_list_filename)}"

          return basename if dirname == '.'

          File.join(
            dirname,
            basename
          )
        end

        def build_cursor_tracker_key
          "#{CURSOR_TRACKER_REDIS_KEY_PREFIX}#{File.basename(orphan_list_filename)}"
        end

        def initialize_files
          @orphan_list_file = File.open(orphan_list_filename, 'r')

          # If the deleted list file already exists, and this is not a force restart,
          # new entries will be appended to it. Otherwise, force restart will
          # cause a truncation of the existing file.
          mode = force_restart ? 'w+' : 'a+'
          @deleted_list_file = File.open(deleted_list_filename, mode)
        end

        def each_batch
          cursor_position = resume_from_last_cursor_position.to_i
          orphan_list_file.pos = cursor_position

          orphan_list_file.each_slice(BATCH_SIZE) do |entries|
            yield entries

            save_current_cursor_position(orphan_list_file.pos)
          end

          clear_last_cursor_position
        end

        def orphans_from_batch(entries)
          BatchFromList.new(entries, logger: logger).orphan_objects
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

        def build_fog_file(line)
          # NOTE: If the object store is configured to use bucket prefix, the GenerateList task would have included the
          # bucket_prefix in paths in the orphans list CSV.
          path_with_bucket_prefix, size = line.split(',')
          artifacts_directory.files.new(key: path_with_bucket_prefix, content_length: size)
        end

        def delete_orphan_object(fog_file)
          # Only GCP will return false here if the object being deleted doesn't exist anymore.
          # S3 and Azure will still return true regardless.
          log_deleted_object(fog_file) if fog_file.destroy
        end

        def log_deleted_object(fog_file)
          add_deleted_object_to_list(fog_file)
          log_info("Deleted object #{fog_file.key} (#{fog_file.content_length} bytes)")
        end

        def add_deleted_object_to_list(fog_file)
          # We log the object's generation (GCP-only attribute) because we need this for the GCP rollback task if ever
          deleted_list_file.puts([fog_file.key, fog_file.content_length, fog_file.try(:generation)].compact.join(','))
        end

        def log_info(msg)
          logger.info(msg)
        end
      end
    end
  end
end
