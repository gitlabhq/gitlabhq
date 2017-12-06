module Geo
  class ProjectRegistryFinder < RegistryFinder
    def count_synced_project_registries
      relation =
        if selective_sync?
          legacy_find_synced_project_registries
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
          legacy_find_filtered_failed_project_registries(type)
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

    # @return [ActiveRecord::Relation<Geo::ProjectRegistry>] list of synced projects
    def legacy_find_synced_project_registries
      legacy_find_project_registries(Geo::ProjectRegistry.synced)
    end

    # @return [ActiveRecord::Relation<Geo::ProjectRegistry>] list of projects that sync has failed
    def legacy_find_filtered_failed_project_registries(type = nil)
      project_registries = find_filtered_failed_project_registries(type)
      legacy_find_project_registries(project_registries)
    end

    # @return [ActiveRecord::Relation<Project>]
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

    # @return [ActiveRecord::Relation<Geo::ProjectRegistry>]
    def legacy_find_project_registries(project_registries)
      return Geo::ProjectRegistry.none if project_registries.empty?

      joined_relation = project_registries.joins(<<~SQL)
        INNER JOIN
        (VALUES #{current_node.projects.pluck(:id).map { |id| "(#{id})" }.join(',')})
        projects(id)
        ON #{Geo::ProjectRegistry.table_name}.project_id = projects.id
      SQL

      joined_relation
    end
  end
end
