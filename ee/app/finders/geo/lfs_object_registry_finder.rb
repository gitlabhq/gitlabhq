module Geo
  class LfsObjectRegistryFinder < FileRegistryFinder
    def count_syncable
      syncable.count
    end

    def count_synced
      if aggregate_pushdown_supported?
        find_synced.count
      else
        legacy_find_synced.count
      end
    end

    def count_failed
      if aggregate_pushdown_supported?
        find_failed.count
      else
        legacy_find_failed.count
      end
    end

    def count_synced_missing_on_primary
      if aggregate_pushdown_supported? && !use_legacy_queries?
        fdw_find_synced_missing_on_primary.count
      else
        legacy_find_synced_missing_on_primary.count
      end
    end

    def count_registry
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
    # rubocop: disable CodeReuse/ActiveRecord
    def find_unsynced(batch_size:, except_file_ids: [])
      relation =
        if use_legacy_queries?
          legacy_find_unsynced(except_file_ids: except_file_ids)
        else
          fdw_find_unsynced(except_file_ids: except_file_ids)
        end

      relation.limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def find_migrated_local(batch_size:, except_file_ids: [])
      relation =
        if use_legacy_queries?
          legacy_find_migrated_local(except_file_ids: except_file_ids)
        else
          fdw_find_migrated_local(except_file_ids: except_file_ids)
        end

      relation.limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def syncable
      all.geo_syncable
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def find_retryable_failed_registries(batch_size:, except_file_ids: [])
      find_failed_registries
        .retry_due
        .where.not(file_id: except_file_ids)
        .limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def find_retryable_synced_missing_on_primary_registries(batch_size:, except_file_ids: [])
      find_synced_missing_on_primary_registries
        .retry_due
        .where.not(file_id: except_file_ids)
        .limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    # rubocop: disable CodeReuse/ActiveRecord
    def all
      if selective_sync?
        LfsObject.joins(:projects).where(projects: { id: current_node.projects })
      else
        LfsObject.all
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def find_synced
      if use_legacy_queries?
        legacy_find_synced
      else
        fdw_find_synced
      end
    end

    def find_failed
      if use_legacy_queries?
        legacy_find_failed
      else
        fdw_find_failed
      end
    end

    def find_synced_registries
      Geo::FileRegistry.lfs_objects.synced
    end

    def find_failed_registries
      Geo::FileRegistry.lfs_objects.failed
    end

    def find_synced_missing_on_primary_registries
      find_synced_registries.missing_on_primary
    end

    #
    # FDW accessors
    #

    # rubocop: disable CodeReuse/ActiveRecord
    def fdw_find
      fdw_all.joins("INNER JOIN file_registry ON file_registry.file_id = #{fdw_table}.id")
        .geo_syncable
        .merge(Geo::FileRegistry.lfs_objects)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def fdw_find_unsynced(except_file_ids:)
      fdw_all.joins("LEFT OUTER JOIN file_registry
                                          ON file_registry.file_id = #{fdw_table}.id
                                         AND file_registry.file_type = 'lfs'")
        .geo_syncable
        .where(file_registry: { id: nil })
        .where.not(id: except_file_ids)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def fdw_find_migrated_local(except_file_ids:)
      fdw_all.joins("INNER JOIN file_registry ON file_registry.file_id = #{fdw_table}.id")
        .with_files_stored_remotely
        .where.not(id: except_file_ids)
        .merge(Geo::FileRegistry.lfs_objects)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def fdw_find_synced
      fdw_find.merge(Geo::FileRegistry.synced)
    end

    def fdw_find_synced_missing_on_primary
      fdw_find.merge(Geo::FileRegistry.synced.missing_on_primary)
    end

    def fdw_find_failed
      fdw_find.merge(Geo::FileRegistry.failed)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def fdw_all
      if selective_sync?
        Geo::Fdw::LfsObject.joins(:project).where(projects: { id: current_node.projects })
      else
        Geo::Fdw::LfsObject.all
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def fdw_table
      Geo::Fdw::LfsObject.table_name
    end

    #
    # Legacy accessors (non FDW)
    #

    # rubocop: disable CodeReuse/ActiveRecord
    def legacy_find_synced
      legacy_inner_join_registry_ids(
        syncable,
        find_synced_registries.pluck(:file_id),
        LfsObject
      )
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def legacy_find_failed
      legacy_inner_join_registry_ids(
        syncable,
        find_failed_registries.pluck(:file_id),
        LfsObject
      )
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def legacy_find_unsynced(except_file_ids:)
      registry_file_ids = Geo::FileRegistry.lfs_objects.pluck(:file_id) | except_file_ids

      legacy_left_outer_join_registry_ids(
        syncable,
        registry_file_ids,
        LfsObject
      )
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def legacy_find_migrated_local(except_file_ids:)
      registry_file_ids = Geo::FileRegistry.lfs_objects.pluck(:file_id) - except_file_ids

      legacy_inner_join_registry_ids(
        all.with_files_stored_remotely,
        registry_file_ids,
        LfsObject
      )
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def legacy_find_synced_missing_on_primary
      legacy_inner_join_registry_ids(
        syncable,
        find_synced_missing_on_primary_registries.pluck(:file_id),
        LfsObject
      )
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
