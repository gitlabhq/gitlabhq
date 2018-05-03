module Geo
  class LfsObjectRegistryFinder < FileRegistryFinder
    def count_syncable_lfs_objects
      syncable_lfs_objects.count
    end

    def count_synced_lfs_objects
      if aggregate_pushdown_supported?
        find_synced_lfs_objects.count
      else
        legacy_find_synced_lfs_objects.count
      end
    end

    def count_failed_lfs_objects
      if aggregate_pushdown_supported?
        find_failed_lfs_objects.count
      else
        legacy_find_failed_lfs_objects.count
      end
    end

    def count_synced_missing_on_primary_lfs_objects
      if aggregate_pushdown_supported? && !use_legacy_queries?
        fdw_find_synced_missing_on_primary_lfs_objects.count
      else
        legacy_find_synced_missing_on_primary_lfs_objects.count
      end
    end

    def count_registry_lfs_objects
      Geo::FileRegistry.lfs_objects.count
    end

    # Find limited amount of non replicated lfs objects.
    #
    # You can pass a list with `except_file_ids:` so you can exclude items you
    # already scheduled but haven't finished and aren't persisted to the database yet
    #
    # TODO: Alternative here is to use some sort of window function with a cursor instead
    #       of simply limiting the query and passing a list of items we don't want
    #
    # @param [Integer] batch_size used to limit the results returned
    # @param [Array<Integer>] except_file_ids ids that will be ignored from the query
    def find_unsynced_lfs_objects(batch_size:, except_file_ids: [])
      relation =
        if use_legacy_queries?
          legacy_find_unsynced_lfs_objects(except_file_ids: except_file_ids)
        else
          fdw_find_unsynced_lfs_objects(except_file_ids: except_file_ids)
        end

      relation.limit(batch_size)
    end

    def find_migrated_local_lfs_objects(batch_size:, except_file_ids: [])
      relation =
        if use_legacy_queries?
          legacy_find_migrated_local_lfs_objects(except_file_ids: except_file_ids)
        else
          fdw_find_migrated_local_lfs_objects(except_file_ids: except_file_ids)
        end

      relation.limit(batch_size)
    end

    def lfs_objects
      if selective_sync?
        LfsObject.joins(:projects).where(projects: { id: current_node.projects })
      else
        LfsObject.all
      end
    end

    def syncable_lfs_objects
      lfs_objects.geo_syncable
    end

    def find_retryable_failed_lfs_objects_registries(batch_size:, except_file_ids: [])
      find_failed_lfs_objects_registries
        .retry_due
        .where.not(file_id: except_file_ids)
        .limit(batch_size)
    end

    def find_retryable_synced_missing_on_primary_lfs_objects_registries(batch_size:, except_file_ids: [])
      find_synced_missing_on_primary_lfs_objects_registries
        .retry_due
        .where.not(file_id: except_file_ids)
        .limit(batch_size)
    end

    def find_failed_lfs_objects_registries
      Geo::FileRegistry.lfs_objects.failed
    end

    def find_synced_missing_on_primary_lfs_objects_registries
      Geo::FileRegistry.lfs_objects.synced.missing_on_primary
    end

    private

    def find_synced_lfs_objects
      if use_legacy_queries?
        legacy_find_synced_lfs_objects
      else
        fdw_find_synced_lfs_objects
      end
    end

    def find_failed_lfs_objects
      if use_legacy_queries?
        legacy_find_failed_lfs_objects
      else
        fdw_find_failed_lfs_objects
      end
    end

    #
    # FDW accessors
    #

    def fdw_find_lfs_objects
      fdw_lfs_objects.joins("INNER JOIN file_registry ON file_registry.file_id = #{fdw_lfs_objects_table}.id")
        .geo_syncable
        .merge(Geo::FileRegistry.lfs_objects)
    end

    def fdw_find_unsynced_lfs_objects(except_file_ids:)
      fdw_lfs_objects.joins("LEFT OUTER JOIN file_registry
                                          ON file_registry.file_id = #{fdw_lfs_objects_table}.id
                                         AND file_registry.file_type = 'lfs'")
        .geo_syncable
        .where(file_registry: { id: nil })
        .where.not(id: except_file_ids)
    end

    def fdw_find_migrated_local_lfs_objects(except_file_ids:)
      fdw_lfs_objects.joins("INNER JOIN file_registry ON file_registry.file_id = #{fdw_lfs_objects_table}.id")
        .with_files_stored_remotely
        .where.not(id: except_file_ids)
        .merge(Geo::FileRegistry.lfs_objects)
    end

    def fdw_find_synced_lfs_objects
      fdw_find_lfs_objects.merge(Geo::FileRegistry.synced)
    end

    def fdw_find_synced_missing_on_primary_lfs_objects
      fdw_find_lfs_objects.merge(Geo::FileRegistry.synced.missing_on_primary)
    end

    def fdw_find_failed_lfs_objects
      fdw_find_lfs_objects.merge(Geo::FileRegistry.failed)
    end

    def fdw_lfs_objects
      if selective_sync?
        Geo::Fdw::LfsObject.joins(:project).where(projects: { id: current_node.projects })
      else
        Geo::Fdw::LfsObject.all
      end
    end

    def fdw_lfs_objects_table
      Geo::Fdw::LfsObject.table_name
    end

    #
    # Legacy accessors (non FDW)
    #

    def legacy_find_synced_lfs_objects
      legacy_inner_join_registry_ids(
        syncable_lfs_objects,
        Geo::FileRegistry.lfs_objects.synced.pluck(:file_id),
        LfsObject
      )
    end

    def legacy_find_failed_lfs_objects
      legacy_inner_join_registry_ids(
        syncable_lfs_objects,
        find_failed_lfs_objects_registries.pluck(:file_id),
        LfsObject
      )
    end

    def legacy_find_unsynced_lfs_objects(except_file_ids:)
      registry_file_ids = legacy_pluck_registry_file_ids(file_types: :lfs) | except_file_ids

      legacy_left_outer_join_registry_ids(
        syncable_lfs_objects,
        registry_file_ids,
        LfsObject
      )
    end

    def legacy_find_migrated_local_lfs_objects(except_file_ids:)
      registry_file_ids = Geo::FileRegistry.lfs_objects.pluck(:file_id) - except_file_ids

      legacy_inner_join_registry_ids(
        lfs_objects.with_files_stored_remotely,
        registry_file_ids,
        LfsObject
      )
    end

    def legacy_find_synced_missing_on_primary_lfs_objects
      legacy_inner_join_registry_ids(
        syncable_lfs_objects,
        Geo::FileRegistry.lfs_objects.synced.missing_on_primary.pluck(:file_id),
        LfsObject
      )
    end
  end
end
