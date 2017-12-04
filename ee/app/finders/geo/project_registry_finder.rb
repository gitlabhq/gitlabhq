module Geo
  class ProjectRegistryFinder < RegistryFinder
    def count_synced_projects
      relation =
        if selective_sync?
          legacy_find_synced_projects
        else
          find_synced_projects_registries
        end

      relation.count
    end

    def count_failed_projects
      relation =
        if selective_sync?
          legacy_find_failed_projects
        else
          find_failed_projects_registries
        end

      relation.count
    end

    def find_unsynced_projects(batch_size:)
      relation =
        if fdw?
          fdw_find_unsynced_projects
        else
          legacy_find_unsynced_projects
        end

      relation.limit(batch_size)
    end

    def find_projects_updated_recently(batch_size:)
      relation =
        if fdw?
          fdw_find_projects_updated_recently
        else
          legacy_find_projects_updated_recently
        end

      relation.limit(batch_size)
    end

    protected

    def find_synced_projects_registries
      Geo::ProjectRegistry.synced
    end

    def find_failed_projects_registries
      Geo::ProjectRegistry.failed
    end

    #
    # FDW accessors
    #

    def fdw_table
      Geo::Fdw::Project.table_name
    end

    # @return [ActiveRecord::Relation<Geo::Fdw::Project>]
    def fdw_find_unsynced_projects
      Geo::Fdw::Project.joins("LEFT OUTER JOIN project_registry ON project_registry.project_id = #{fdw_table}.id")
        .where('project_registry.project_id IS NULL')
    end

    # @return [ActiveRecord::Relation<Geo::Fdw::Project>]
    def fdw_find_projects_updated_recently
      Geo::Fdw::Project.joins("INNER JOIN project_registry ON project_registry.project_id = #{fdw_table}.id")
        .merge(Geo::ProjectRegistry.dirty)
        .merge(Geo::ProjectRegistry.retry_due)
    end

    #
    # Legacy accessors (non FDW)
    #

    # @return [ActiveRecord::Relation<Project>] list of unsynced projects
    def legacy_find_unsynced_projects
      registry_project_ids = current_node.project_registries.pluck(:project_id)
      return current_node.projects if registry_project_ids.empty?

      joined_relation = current_node.projects.joins(<<~SQL)
        LEFT OUTER JOIN
        (VALUES #{registry_project_ids.map { |id| "(#{id}, 't')" }.join(',')})
        project_registry(project_id, registry_present)
        ON projects.id = project_registry.project_id
      SQL

      joined_relation.where(project_registry: { registry_present: [nil, false] })
    end

    # @return [ActiveRecord::Relation<Project>] list of projects updated recently
    def legacy_find_projects_updated_recently
      legacy_find_projects(current_node.project_registries.dirty.retry_due.pluck(:project_id))
    end

    # @return [ActiveRecord::Relation<Project>] list of synced projects
    def legacy_find_synced_projects
      legacy_find_projects(Geo::ProjectRegistry.synced.pluck(:project_id))
    end

    # @return [ActiveRecord::Relation<Project>] list of projects that sync has failed
    def legacy_find_failed_projects
      legacy_find_projects(Geo::ProjectRegistry.failed.pluck(:project_id))
    end

    def legacy_find_projects(registry_project_ids)
      return Project.none if registry_project_ids.empty?

      joined_relation = current_node.projects.joins(<<~SQL)
        INNER JOIN
        (VALUES #{registry_project_ids.map { |id| "(#{id})" }.join(',')})
        project_registry(project_id)
        ON #{Project.table_name}.id = project_registry.project_id
      SQL

      joined_relation
    end
  end
end
