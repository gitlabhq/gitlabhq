module Geo
  class MigratedLocalFilesCleanUpWorker < ::Geo::Scheduler::Secondary::SchedulerWorker
    include ::CronjobQueue

    MAX_CAPACITY = 1000

    def perform
      # No need to run when nothing is configured to be in Object Storage
      return unless attachments_object_store_enabled? ||
          lfs_objects_object_store_enabled? ||
          job_artifacts_object_store_enabled?

      super
    end

    private

    def max_capacity
      MAX_CAPACITY
    end

    def schedule_job(object_type, object_db_id)
      job_id = ::Geo::FileRegistryRemovalWorker.perform_async(object_type.to_s, object_db_id)

      if job_id
        retval = { id: object_db_id, type: object_type, job_id: job_id }
        log_info('Scheduled Geo::FileRegistryRemovalWorker', retval)

        retval
      end
    end

    def load_pending_resources
      find_migrated_local_objects(batch_size: db_retrieve_batch_size)
    end

    def find_migrated_local_objects(batch_size:)
      lfs_object_ids = find_migrated_local_lfs_objects_ids(batch_size: batch_size)
      attachment_ids = find_migrated_local_attachments_ids(batch_size: batch_size)
      job_artifact_ids = find_migrated_local_job_artifacts_ids(batch_size: batch_size)

      take_batch(lfs_object_ids, attachment_ids, job_artifact_ids)
    end

    def find_migrated_local_lfs_objects_ids(batch_size:)
      return [] unless lfs_objects_object_store_enabled?

      lfs_objects_finder.find_migrated_local_lfs_objects(batch_size: batch_size, except_file_ids: scheduled_file_ids(:lfs))
                        .pluck(:id)
                        .map { |id| ['lfs', id] }
    end

    def find_migrated_local_attachments_ids(batch_size:)
      return [] unless attachments_object_store_enabled?

      attachments_finder.find_migrated_local_attachments(batch_size: batch_size, except_file_ids: scheduled_file_ids(Geo::FileService::DEFAULT_OBJECT_TYPES))
                        .pluck(:uploader, :id)
                        .map { |uploader, id| [uploader.sub(/Uploader\z/, '').underscore, id] }
    end

    def find_migrated_local_job_artifacts_ids(batch_size:)
      return [] unless job_artifacts_object_store_enabled?

      job_artifacts_finder.find_migrated_local_job_artifacts(batch_size: batch_size, except_artifact_ids: scheduled_file_ids(:job_artifact))
                          .pluck(:id)
                          .map { |id| ['job_artifact', id] }
    end

    def scheduled_file_ids(file_types)
      file_types = Array(file_types)
      file_types = file_types.map(&:to_s)

      scheduled_jobs.select { |data| file_types.include?(data[:type].to_s) }.map { |data| data[:id] }
    end

    def attachments_object_store_enabled?
      FileUploader.object_store_enabled?
    end

    def lfs_objects_object_store_enabled?
      LfsObjectUploader.object_store_enabled?
    end

    def job_artifacts_object_store_enabled?
      JobArtifactUploader.object_store_enabled?
    end

    def attachments_finder
      @attachments_finder ||= AttachmentRegistryFinder.new(current_node: current_node)
    end

    def lfs_objects_finder
      @lfs_objects_finder ||= LfsObjectRegistryFinder.new(current_node: current_node)
    end

    def job_artifacts_finder
      @job_artifacts_finder ||= JobArtifactRegistryFinder.new(current_node: current_node)
    end
  end
end
