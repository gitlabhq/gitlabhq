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

    def find_failed_project_registries(type = nil)
      relation =
        if selective_sync?
          legacy_find_failed_project_registries(type)
        else
          find_failed_projects_registries(type)
        end

      relation
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

    def find_failed_projects_registries(type = nil)
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
      registry_project_ids = Geo::ProjectRegistry.pluck(:project_id)
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
      legacy_find_projects(Geo::ProjectRegistry.dirty.retry_due.pluck(:project_id))
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

    def legacy_find_failed_project_registries(type)
      project_registries = find_failed_projects_registries(type)
      return Geo::ProjectRegistry.none if project_registries.empty?

      joined_relation = project_registries.joins(<<~SQL)
        INNER JOIN
        (VALUES #{current_node.projects.pluck(:id).map { |id| "(#{id})" }.join(',')})
        projects(project_id)
        ON #{Geo::ProjectRegistry.table_name}.id = projects.project_id
      SQL

      joined_relation
    end
  end
end
