module Geo
  class FileDownloadDispatchWorker < Geo::BaseSchedulerWorker
    private

    def schedule_job(object_db_id, object_type)
      job_id = GeoFileDownloadWorker.perform_async(object_type, object_db_id)

      { id: object_db_id, type: object_type, job_id: job_id } if job_id
    end

    def load_pending_resources
      lfs_object_ids = find_lfs_object_ids
      objects_ids    = find_object_ids

      interleave(lfs_object_ids, objects_ids)
    end

    def find_object_ids
      downloaded_ids = find_downloaded_ids(Geo::FileService::DEFAULT_OBJECT_TYPES)

      unsynched_downloads = filter_downloaded_ids(
        current_node.uploads, downloaded_ids, Upload.table_name)

      unsynched_downloads
        .order(created_at: :desc)
        .limit(db_retrieve_batch_size)
        .pluck(:id, :uploader)
        .map { |id, uploader| [id, uploader.sub(/Uploader\z/, '').underscore] }
    end

    def find_lfs_object_ids
      downloaded_ids = find_downloaded_ids([:lfs])

      unsynched_downloads = filter_downloaded_ids(
        current_node.lfs_objects, downloaded_ids, LfsObject.table_name)

      unsynched_downloads
        .order(created_at: :desc)
        .limit(db_retrieve_batch_size)
        .pluck(:id)
        .map { |id| [id, :lfs] }
    end

    # This query requires data from two different databases, and unavoidably
    # plucks a list of file IDs from one into the other. This will not scale
    # well with the number of synchronized files--the query will increase
    # linearly in size--so this should be replaced with postgres_fdw ASAP.
    def filter_downloaded_ids(objects, downloaded_ids, table_name)
      return objects if downloaded_ids.empty?

      joined_relation = objects.joins(<<~SQL)
        LEFT OUTER JOIN
        (VALUES #{downloaded_ids.map { |id| "(#{id}, 't')" }.join(',')})
         file_registry(file_id, registry_present)
         ON #{table_name}.id = file_registry.file_id
      SQL

      joined_relation.where(file_registry: { registry_present: [nil, false] })
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
