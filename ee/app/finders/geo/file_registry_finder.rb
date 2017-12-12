module Geo
  class FileRegistryFinder < RegistryFinder
    def find_failed_objects(batch_size:)
      Geo::FileRegistry
        .failed
        .retry_due
        .limit(batch_size)
        .pluck(:file_id, :file_type)
    end

    # Find limited amount of non replicated lfs objects.
    #
    # You can pass a list with `except_registry_ids:` so you can exclude items you
    # already scheduled but haven't finished and persisted to the database yet
    #
    # TODO: Alternative here is to use some sort of window function with a cursor instead
    #       of simply limiting the query and passing a list of items we don't want
    #
    # @param [Integer] batch_size used to limit the results returned
    # @param [Array<Integer>] except_registry_ids ids that will be ignored from the query
    def find_nonreplicated_lfs_objects(batch_size:, except_registry_ids:)
      # Selective project replication adds a wrinkle to FDW queries, so
      # we fallback to the legacy version for now.
      relation =
        if use_legacy_queries?
          legacy_find_nonreplicated_lfs_objects(except_registry_ids: except_registry_ids)
        else
          fdw_find_nonreplicated_lfs_objects
        end

      relation
        .limit(batch_size)
        .pluck(:id)
        .map { |id| [id, :lfs] }
    end

    # Find limited amount of non replicated uploads.
    #
    # You can pass a list with `except_registry_ids:` so you can exclude items you
    # already scheduled but haven't finished and persisted to the database yet
    #
    # TODO: Alternative here is to use some sort of window function with a cursor instead
    #       of simply limiting the query and passing a list of items we don't want
    #
    # @param [Integer] batch_size used to limit the results returned
    # @param [Array<Integer>] except_registry_ids ids that will be ignored from the query
    def find_nonreplicated_uploads(batch_size:, except_registry_ids:)
      # Selective project replication adds a wrinkle to FDW queries, so
      # we fallback to the legacy version for now.
      relation =
        if use_legacy_queries?
          legacy_find_nonreplicated_uploads(except_registry_ids: except_registry_ids)
        else
          fdw_find_nonreplicated_uploads
        end

      relation
        .limit(batch_size)
        .pluck(:id, :uploader)
        .map { |id, uploader| [id, uploader.sub(/Uploader\z/, '').underscore] }
    end

    protected

    #
    # FDW accessors
    #

    def fdw_find_nonreplicated_lfs_objects
      fdw_table = Geo::Fdw::LfsObject.table_name

      # Filter out objects in object storage (this is done in GeoNode#lfs_objects)
      Geo::Fdw::LfsObject.joins("LEFT OUTER JOIN file_registry
                                              ON file_registry.file_id = #{fdw_table}.id
                                             AND file_registry.file_type = 'lfs'")
        .where("#{fdw_table}.file_store IS NULL OR #{fdw_table}.file_store = #{LfsObjectUploader::Store::LOCAL}")
        .where('file_registry.file_id IS NULL')
    end

    def fdw_find_nonreplicated_uploads
      fdw_table = Geo::Fdw::Upload.table_name
      upload_types = Geo::FileService::DEFAULT_OBJECT_TYPES.map { |val| "'#{val}'" }.join(',')

      Geo::Fdw::Upload.joins("LEFT OUTER JOIN file_registry
                                           ON file_registry.file_id = #{fdw_table}.id
                                          AND file_registry.file_type IN (#{upload_types})")
        .where('file_registry.file_id IS NULL')
    end

    #
    # Legacy accessors (non FDW)
    #

    def legacy_find_nonreplicated_lfs_objects(except_registry_ids:)
      registry_ids = legacy_pluck_registry_ids(file_types: :lfs, except_registry_ids: except_registry_ids)

      legacy_filter_registry_ids(
        lfs_objects_finder.lfs_objects,
        registry_ids,
        LfsObject.table_name
      )
    end

    def legacy_find_nonreplicated_uploads(except_registry_ids:)
      registry_ids = legacy_pluck_registry_ids(file_types: Geo::FileService::DEFAULT_OBJECT_TYPES, except_registry_ids: except_registry_ids)

      legacy_filter_registry_ids(
        attachments_finder.uploads,
        registry_ids,
        Upload.table_name
      )
    end

    # This query requires data from two different databases, and unavoidably
    # plucks a list of file IDs from one into the other. This will not scale
    # well with the number of synchronized files--the query will increase
    # linearly in size--so this should be replaced with postgres_fdw ASAP.
    def legacy_filter_registry_ids(objects, registry_ids, table_name)
      return objects if registry_ids.empty?

      joined_relation = objects.joins(<<~SQL)
        LEFT OUTER JOIN
        (VALUES #{registry_ids.map { |id| "(#{id}, 't')" }.join(',')})
         file_registry(file_id, registry_present)
         ON #{table_name}.id = file_registry.file_id
      SQL

      joined_relation.where(file_registry: { registry_present: [nil, false] })
    end

    def legacy_pluck_registry_ids(file_types:, except_registry_ids:)
      ids = Geo::FileRegistry.where(file_type: file_types).pluck(:file_id)
      (ids + except_registry_ids).uniq
    end

    def attachments_finder
      @attachments_finder ||= AttachmentRegistryFinder.new(current_node: current_node)
    end

    def lfs_objects_finder
      @lfs_objects_finder ||= LfsObjectRegistryFinder.new(current_node: current_node)
    end
  end
end
