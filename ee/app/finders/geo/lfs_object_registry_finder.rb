module Geo
  class LfsObjectRegistryFinder < RegistryFinder
    def find_synced_lfs_objects
      relation =
        if fdw?
          fdw_find_synced_lfs_objects
        else
          legacy_find_synced_lfs_objects
        end

      relation
    end

    def find_failed_lfs_objects
      relation =
        if fdw?
          fdw_find_failed_lfs_objects
        else
          legacy_find_failed_lfs_objects
        end

      relation
    end

    private

    def lfs_objects
      lfs_object_model = fdw? ? Geo::Fdw::LfsObject : LfsObject

      relation =
        if selective_sync?
          lfs_object_model.joins(:projects).where(projects: { id: current_node.projects })
        else
          lfs_object_model.all
        end

      relation.with_files_stored_locally
    end

    #
    # FDW accessors
    #

    def fdw_table
      Geo::Fdw::LfsObject.table_name
    end

    def fdw_find_synced_lfs_objects
      lfs_objects.joins("INNER JOIN file_registry ON file_registry.file_id = #{fdw_table}.id")
        .merge(Geo::FileRegistry.lfs_objects)
        .merge(Geo::FileRegistry.synced)
    end

    def fdw_find_failed_lfs_objects
      lfs_objects.joins("INNER JOIN file_registry ON file_registry.file_id = #{fdw_table}.id")
        .merge(Geo::FileRegistry.lfs_objects)
        .merge(Geo::FileRegistry.failed)
    end

    #
    # Legacy accessors (non FDW)
    #

    def legacy_find_synced_lfs_objects
      legacy_find_lfs_objects(Geo::FileRegistry.lfs_objects.synced.pluck(:file_id))
    end

    def legacy_find_failed_lfs_objects
      legacy_find_lfs_objects(Geo::FileRegistry.lfs_objects.failed.pluck(:file_id))
    end

    def legacy_find_lfs_objects(registry_file_ids)
      return LfsObject.none if registry_file_ids.empty?

      joined_relation = lfs_objects.joins(<<~SQL)
        INNER JOIN
        (VALUES #{registry_file_ids.map { |id| "(#{id})" }.join(',')})
        file_registry(file_id)
        ON #{LfsObject.table_name}.id = file_registry.file_id
      SQL

      joined_relation
    end
  end
end
