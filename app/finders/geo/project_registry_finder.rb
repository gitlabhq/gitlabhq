module Geo
  class ProjectRegistryFinder
    attr_reader :current_node

    def initialize(current_node: nil)
      @current_node = current_node
    end

    def find_unsynced_projects(batch_size:)
      # Selective project replication adds a wrinkle to FDW queries, so
      # we fallback to the legacy version for now.
      relation =
        if Gitlab::Geo.fdw? && !selective_sync
          fdw_find_unsynced_projects
        else
          legacy_find_unsynced_projects
        end

      relation.limit(batch_size)
    end

    def find_projects_updated_recently(batch_size:)
      # Selective project replication adds a wrinkle to FDW queries, so
      # we fallback to the legacy version for now.
      relation =
        if Gitlab::Geo.fdw? && !selective_sync
          fdw_find_projects_updated_recently
        else
          legacy_find_projects_updated_recently
        end

      relation.limit(batch_size)
    end

    protected

    def selective_sync
      current_node.restricted_project_ids
    end

    #
    # FDW accessors
    #

     # @return [ActiveRecord::Relation<Geo::Fdw::Project>]
    def fdw_find_unsynced_projects
      fdw_table = Geo::Fdw::Project.table_name

      Geo::Fdw::Project.joins("LEFT OUTER JOIN project_registry ON project_registry.project_id = #{fdw_table}.id")
        .where('project_registry.project_id IS NULL')
    end

     # @return [ActiveRecord::Relation<Geo::Fdw::Project>]
    def fdw_find_projects_updated_recently
      fdw_table = Geo::Fdw::Project.table_name

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
      registry_project_ids = current_node.project_registries.dirty.retry_due.pluck(:project_id)
      return Project.none if registry_project_ids.empty?

      joined_relation = current_node.projects.joins(<<~SQL)
        INNER JOIN
        (VALUES #{registry_project_ids.map { |id| "(#{id})" }.join(',')})
        project_registry(project_id)
        ON projects.id = project_registry.project_id
      SQL

      joined_relation
    end
  end
end
