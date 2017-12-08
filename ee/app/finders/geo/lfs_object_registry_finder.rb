module Geo
  class LfsObjectRegistryFinder < RegistryFinder
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

    def legacy_find_synced_lfs_objects
      legacy_find_lfs_objects(find_synced_lfs_objects_registries.pluck(:file_id))
    end

    def legacy_find_failed_lfs_objects
      legacy_find_lfs_objects(find_failed_lfs_objects_registries.pluck(:file_id))
    end

    def legacy_find_lfs_objects(registry_file_ids)
      return LfsObject.none if registry_file_ids.empty?

      lfs_objects = LfsObject.joins(:projects)
        .where(projects: { id: current_node.projects })
        .with_files_stored_locally

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
