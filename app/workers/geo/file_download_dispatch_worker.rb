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

    def load_pending_resources
      unsynced = find_unsynced_objects
      failed = find_failed_objects

      interleave(unsynced, failed)
    end

    def find_unsynced_objects
      lfs_object_ids = find_lfs_object_ids
      upload_objects_ids = find_upload_object_ids

      interleave(lfs_object_ids, upload_objects_ids)
    end

    def find_failed_objects
      Geo::FileRegistry
        .failed
        .limit(db_retrieve_batch_size)
        .pluck(:file_id, :file_type)
    end

    def find_lfs_object_ids
      # Selective project replication adds a wrinkle to FDW queries, so
      # we fallback to the legacy version for now.
      if Gitlab::Geo.fdw? && !current_node.restricted_project_ids
        fdw_find_lfs_object_ids
      else
        legacy_find_lfs_object_ids
      end
    end

    def find_upload_object_ids
      # Selective project replication adds a wrinkle to FDW queries, so
      # we fallback to the legacy version for now.
      if Gitlab::Geo.fdw? && !current_node.restricted_project_ids
        fdw_find_upload_object_ids
      else
        legacy_find_upload_object_ids
      end
    end

    def fdw_find_lfs_object_ids
      fdw_table = "#{Gitlab::Geo.fdw_schema}.lfs_objects"

      # Filter out objects in object storage (this is done in GeoNode#lfs_objects)
      LfsObject.fdw.joins("LEFT OUTER JOIN file_registry ON file_registry.file_id = #{fdw_table}.id AND file_registry.file_type = 'lfs'")
        .where("#{fdw_table}.file_store IS NULL OR #{fdw_table}.file_store = #{LfsObjectUploader::LOCAL_STORE}")
        .where('file_registry.file_id IS NULL')
        .order(created_at: :desc)
        .limit(db_retrieve_batch_size)
        .pluck(:id)
        .map { |id| [id, :lfs] }
    end

    def fdw_find_upload_object_ids
      fdw_table = "#{Gitlab::Geo.fdw_schema}.uploads"
      obj_types = Geo::FileService::DEFAULT_OBJECT_TYPES.map { |val| "'#{val}'" }.join(',')

      Upload.fdw.joins("LEFT OUTER JOIN file_registry ON file_registry.file_id = #{fdw_table}.id AND file_registry.file_type IN (#{obj_types})")
        .where('file_registry.file_id IS NULL')
        .order(created_at: :desc)
        .limit(db_retrieve_batch_size)
        .pluck(:id, :uploader)
        .map { |id, uploader| [id, uploader.sub(/Uploader\z/, '').underscore] }
    end

    def legacy_find_upload_object_ids
      unsynced_downloads = legacy_filter_registry_ids(
        current_node.uploads,
        Geo::FileService::DEFAULT_OBJECT_TYPES,
        Upload.table_name
      )

      unsynced_downloads
        .limit(db_retrieve_batch_size)
        .pluck(:id, :uploader)
        .map { |id, uploader| [id, uploader.sub(/Uploader\z/, '').underscore] }
    end

    def legacy_find_lfs_object_ids
      unsynced_downloads = legacy_filter_registry_ids(
        current_node.lfs_objects,
        [:lfs],
        LfsObject.table_name
      )

      unsynced_downloads
        .limit(db_retrieve_batch_size)
        .pluck(:id)
        .map { |id| [id, :lfs] }
    end

    # This query requires data from two different databases, and unavoidably
    # plucks a list of file IDs from one into the other. This will not scale
    # well with the number of synchronized files--the query will increase
    # linearly in size--so this should be replaced with postgres_fdw ASAP.
    def legacy_filter_registry_ids(objects, file_types, table_name)
      registry_ids = legacy_pluck_registry_ids(Geo::FileRegistry, file_types)

      return objects if registry_ids.empty?

      joined_relation = objects.joins(<<~SQL)
        LEFT OUTER JOIN
        (VALUES #{registry_ids.map { |id| "(#{id}, 't')" }.join(',')})
         file_registry(file_id, registry_present)
         ON #{table_name}.id = file_registry.file_id
      SQL

      joined_relation.where(file_registry: { registry_present: [nil, false] })
    end

    def legacy_pluck_registry_ids(relation, file_types)
      ids = relation.where(file_type: file_types).pluck(:file_id)
      (ids + scheduled_file_ids(file_types)).uniq
    end

    def scheduled_file_ids(types)
      scheduled_jobs.select { |data| types.include?(data[:type]) }.map { |data| data[:id] }
    end
  end
end
