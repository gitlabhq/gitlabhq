module Geo
  class ProjectRegistryFinder < RegistryFinder
    def count_projects
      current_node.projects.count
    end

    def count_synced_project_registries
      relation =
        if selective_sync?
          legacy_find_synced_projects
        else
          find_synced_project_registries
        end

      relation.count
    end

    def count_failed_project_registries
      find_failed_project_registries.count
    end

    def find_failed_project_registries(type = nil)
      relation =
        if selective_sync?
          legacy_find_filtered_failed_projects(type)
        else
          find_filtered_failed_project_registries(type)
        end

      relation
    end

    def find_unsynced_projects(batch_size:)
      relation =
        if use_legacy_queries?
          legacy_find_unsynced_projects
        else
          fdw_find_unsynced_projects
        end

      relation.limit(batch_size)
    end

    def find_projects_updated_recently(batch_size:)
      relation =
        if use_legacy_queries?
          legacy_find_projects_updated_recently
        else
          fdw_find_projects_updated_recently
        end

      relation.limit(batch_size)
    end

    protected

    def find_synced_project_registries
      Geo::ProjectRegistry.synced
    end

    def find_filtered_failed_project_registries(type = nil)
      case type
      when 'repository'
        Geo::ProjectRegistry.failed_repos
      when 'wiki'
        Geo::ProjectRegistry.failed_wikis
      else
        Geo::ProjectRegistry.failed
      end
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
        .where(project_registry: { project_id: nil })
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
      legacy_left_outer_join_registry_ids(
        current_node.projects,
        Geo::ProjectRegistry.pluck(:project_id),
        Project
      )
    end

    # @return [ActiveRecord::Relation<Project>] list of projects updated recently
    def legacy_find_projects_updated_recently
      legacy_inner_join_registry_ids(
        current_node.projects,
        Geo::ProjectRegistry.dirty.retry_due.pluck(:project_id),
        Project
      )
    end

    # @return [ActiveRecord::Relation<Project>] list of synced projects
    def legacy_find_synced_projects
      legacy_inner_join_registry_ids(
        current_node.projects,
        Geo::ProjectRegistry.synced.pluck(:project_id),
        Project
      )
    end

    # @return [ActiveRecord::Relation<Project>] list of projects that sync has failed
    def legacy_find_filtered_failed_projects(type = nil)
      legacy_inner_join_registry_ids(
        find_filtered_failed_project_registries(type),
        current_node.projects.pluck(:id),
        Geo::ProjectRegistry,
        foreign_key: :project_id
      )
    end
  end
end
