module Geo
  class FileDownloadDispatchWorker < Geo::BaseSchedulerWorker
    private

    def schedule_job(object_db_id, object_type)
      job_id = GeoFileDownloadWorker.perform_async(object_type, object_db_id)

      { id: object_db_id, type: object_type, job_id: job_id } if job_id
    end

    def load_pending_resources
      restricted_project_ids = Gitlab::Geo.current_node.project_ids
      lfs_object_ids         = find_lfs_object_ids(restricted_project_ids)
      objects_ids            = find_object_ids(restricted_project_ids)

      interleave(lfs_object_ids, objects_ids)
    end

    def find_object_ids(restricted_project_ids)
      downloaded_ids = find_downloaded_ids([:attachment, :avatar, :file])

      current_node.uploads
                  .where.not(id: downloaded_ids)
                  .order(created_at: :desc)
                  .limit(db_retrieve_batch_size)
                  .pluck(:id, :uploader)
                  .map { |id, uploader| [id, uploader.sub(/Uploader\z/, '').downcase] }
    end

    def find_lfs_object_ids(restricted_project_ids)
      downloaded_ids = find_downloaded_ids([:lfs])

      current_node.lfs_objects
                  .where.not(id: downloaded_ids)
                  .order(created_at: :desc)
                  .limit(db_retrieve_batch_size)
                  .pluck(:id)
                  .map { |id| [id, :lfs] }
    end

    def find_downloaded_ids(file_types)
      downloaded_ids = Geo::FileRegistry.where(file_type: file_types).pluck(:file_id)
      (downloaded_ids + scheduled_file_ids(file_types)).uniq
    end

    def scheduled_file_ids(types)
      scheduled_jobs.select { |data| types.include?(data[:type]) }.map { |data| data[:id] }
    end
  end
end
