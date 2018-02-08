module Geo
  class LfsObjectRegistryFinder < FileRegistryFinder
    def count_lfs_objects
      lfs_objects.count
    end

    def count_synced_lfs_objects
      relation =
        if selective_sync?
          legacy_find_synced_lfs_objects
        else
          find_synced_lfs_objects_registries
        end

      relation.count
    end

    def count_failed_lfs_objects
      relation =
        if selective_sync?
          legacy_find_failed_lfs_objects
        else
          find_failed_lfs_objects_registries
        end

      relation.count
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
    def find_unsynced_lfs_objects(batch_size:, except_registry_ids: [])
      relation =
        if use_legacy_queries?
          legacy_find_unsynced_lfs_objects(except_registry_ids: except_registry_ids)
        else
          fdw_find_unsynced_lfs_objects(except_registry_ids: except_registry_ids)
        end

      relation.limit(batch_size)
    end

    def lfs_objects
      relation =
        if selective_sync?
          LfsObject.joins(:projects).where(projects: { id: current_node.projects })
        else
          LfsObject.all
        end

      relation.with_files_stored_locally
    end

    private

    def find_synced_lfs_objects_registries
      Geo::FileRegistry.lfs_objects.synced
    end

    def find_failed_lfs_objects_registries
      Geo::FileRegistry.lfs_objects.failed
    end

    #
    # FDW accessors
    #

    def fdw_find_unsynced_lfs_objects(except_registry_ids:)
      fdw_table = Geo::Fdw::LfsObject.table_name

      # Filter out objects in object storage (this is done in GeoNode#lfs_objects)
      Geo::Fdw::LfsObject.joins("LEFT OUTER JOIN file_registry
                                              ON file_registry.file_id = #{fdw_table}.id
                                             AND file_registry.file_type = 'lfs'")
        .with_files_stored_locally
        .where(file_registry: { id: nil })
        .where.not(id: except_registry_ids)
    end

    #
    # Legacy accessors (non FDW)
    #

    def legacy_find_synced_lfs_objects
      legacy_inner_join_registry_ids(
        lfs_objects,
        find_synced_lfs_objects_registries.pluck(:file_id),
        LfsObject
      )
    end

    def legacy_find_failed_lfs_objects
      legacy_inner_join_registry_ids(
        lfs_objects,
        find_failed_lfs_objects_registries.pluck(:file_id),
        LfsObject
      )
    end

    def legacy_find_unsynced_lfs_objects(except_registry_ids:)
      registry_ids = legacy_pluck_registry_ids(file_types: :lfs, except_registry_ids: except_registry_ids)

      legacy_left_outer_join_registry_ids(
        lfs_objects,
        registry_ids,
        LfsObject
      )
    end
  end
end
