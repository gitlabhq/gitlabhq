# frozen_string_literal: true

module Gitlab
  module Cleanup
    class OrphanLfsObjects
      attr_reader :dry_run, :logger

      BATCH_SIZE = 1000
      PROGRESS_INTERVAL = 1000

      def initialize(dry_run: true, logger: nil)
        @dry_run = dry_run
        @logger = logger || Gitlab::AppLogger
      end

      def run!
        log_info("Looking for LFS objects with missing files")

        process_missing_objects
      end

      private

      def each_missing_lfs_object
        missing_count = 0
        checked_count = 0

        # rubocop:disable CodeReuse/ActiveRecord -- Cleanup task needs direct DB access
        LfsObject.includes(:lfs_objects_projects).find_each(batch_size: BATCH_SIZE) do |lfs_object|
          # rubocop:enable CodeReuse/ActiveRecord
          checked_count += 1
          log_progress(checked_count, missing_count)
          next if file_exists?(lfs_object)

          yield lfs_object
          missing_count += 1
        end
      end

      def file_exists?(lfs_object)
        if lfs_object.local_store?
          path = lfs_object.file&.path
          path.present? && File.exist?(path)
        else
          lfs_object.file&.file&.exists?
        end
      rescue StandardError => e
        logger.warn("Error checking LFS object #{lfs_object.oid}: #{e.message}. Skipping.")
        true # skip on error to avoid data loss
      end

      def process_missing_objects
        affected_project_ids = Set.new
        count = 0

        each_missing_lfs_object do |lfs_object|
          linked_project_ids = lfs_object.lfs_objects_projects.map(&:project_id) # preloaded
          linked_count = linked_project_ids.size

          if dry_run
            log_info("Would remove LFS object: #{lfs_object.oid} (linked to #{linked_count} project(s))")
          else
            remove_lfs_object(lfs_object, linked_project_ids, affected_project_ids)
          end

          count += 1
        end

        if count == 0
          log_info("No LFS objects with missing files found")
          return
        end

        update_project_statistics(affected_project_ids) unless dry_run

        log_summary(count)
      end

      def remove_lfs_object(lfs_object, linked_project_ids, affected_project_ids)
        ApplicationRecord.transaction do
          linked_project_ids.each { |id| affected_project_ids << id }
          LfsObjectsProject.lfs_object_in(lfs_object).delete_all
          lfs_object.lfs_objects_projects.reset # clear preloaded cache
          lfs_object.destroy!
        end

        log_info("Removed LFS object: #{lfs_object.oid} (was linked to #{linked_project_ids.size} project(s))")
      rescue ActiveRecord::RecordNotDestroyed => e
        logger.error("Failed to remove LFS object #{lfs_object.oid}: #{e.message}")
      end

      def update_project_statistics(project_ids)
        project_ids.each do |project_id|
          ProjectCacheWorker.perform_async(project_id, [], %w[lfs_objects_size])
        end
      end

      def log_summary(count)
        if dry_run
          log_info("Found #{count} LFS object(s) with missing files")
          log_info("To actually remove these, run with DRY_RUN=false")
        else
          log_info("Removed #{count} LFS object(s) with missing files")
        end
      end

      def log_info(msg)
        logger.info("#{'[DRY RUN] ' if dry_run}#{msg}")
      end

      def log_progress(checked_count, missing_count)
        return unless (checked_count % PROGRESS_INTERVAL) == 0

        log_info("Progress: checked #{checked_count} objects, found #{missing_count} missing so far")
      end
    end
  end
end
