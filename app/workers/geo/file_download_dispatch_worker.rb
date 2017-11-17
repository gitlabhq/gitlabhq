module Geo
  class FileDownloadDispatchWorker < Geo::BaseSchedulerWorker
    private

    def max_capacity
      current_node.files_max_capacity
    end

    def schedule_job(object_db_id, object_type)
      job_id = GeoFileDownloadWorker.perform_async(object_type, object_db_id)

      { id: object_db_id, type: object_type, job_id: job_id } if job_id
    end

    def finder
      @finder ||= RegistryFinder.new(current_node: current_node)
    end

    # Pools for new resources to be transferred
    #
    # @return [Array] resources to be transferred
    def load_pending_resources
      resources = find_unsynced_objects(batch_size: db_retrieve_batch_size)
      remaining_capacity = db_retrieve_batch_size - resources.count

      if remaining_capacity.zero?
        resources
      else
        resources + finder.find_failed_objects(batch_size: remaining_capacity)
      end
    end

    def find_unsynced_objects(batch_size:)
      lfs_object_ids = finder.find_nonreplicated_lfs_objects(batch_size: batch_size, except_registry_ids: scheduled_file_ids(:lfs))
      upload_objects_ids = finder.find_nonreplicated_uploads(batch_size: batch_size, except_registry_ids: scheduled_file_ids(Geo::FileService::DEFAULT_OBJECT_TYPES))

      interleave(lfs_object_ids, upload_objects_ids)
    end

    def scheduled_file_ids(file_types)
      file_types = Array(file_types) unless file_types.is_a? Array

      scheduled_jobs.select { |data| file_types.include?(data[:type]) }.map { |data| data[:id] }
    end
  end
end
