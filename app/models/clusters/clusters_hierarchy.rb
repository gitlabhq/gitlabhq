# frozen_string_literal: true

module Clusters
  class ClustersHierarchy
    DEPTH_COLUMN = :depth

    def initialize(clusterable)
      @clusterable = clusterable
    end

    # Returns clusters in order from deepest to highest group
    def base_and_ancestors
      cte = recursive_cte
      cte_alias = cte.table.alias(model.table_name)

      model
        .unscoped
        .where('clusters.id IS NOT NULL')
        .with
        .recursive(cte.to_arel)
        .from(cte_alias)
        .order(DEPTH_COLUMN => :asc)
    end

    private

    attr_reader :clusterable

    def recursive_cte
      cte = Gitlab::SQL::RecursiveCTE.new(:clusters_cte)

      base_query = case clusterable
                   when ::Group
                     group_clusters_base_query
                   when ::Project
                     project_clusters_base_query
                   else
                     raise ArgumentError, "unknown type for #{clusterable}"
                   end

      cte << base_query
      cte << parent_query(cte)

      cte
    end

    def group_clusters_base_query
      group_parent_id_alias = alias_as_column(groups[:parent_id], 'group_parent_id')
      join_sources = ::Group.left_joins(:clusters).join_sources

      model
        .unscoped
        .select([clusters_star, group_parent_id_alias, "1 AS #{DEPTH_COLUMN}"])
        .where(groups[:id].eq(clusterable.id))
        .from(groups)
        .joins(join_sources)
    end

    def project_clusters_base_query
      projects = ::Project.arel_table
      project_parent_id_alias = alias_as_column(projects[:namespace_id], 'group_parent_id')
      join_sources = ::Project.left_joins(:clusters).join_sources

      model
        .unscoped
        .select([clusters_star, project_parent_id_alias, "1 AS #{DEPTH_COLUMN}"])
        .where(projects[:id].eq(clusterable.id))
        .from(projects)
        .joins(join_sources)
    end

    def parent_query(cte)
      group_parent_id_alias = alias_as_column(groups[:parent_id], 'group_parent_id')

      model
        .unscoped
        .select([clusters_star, group_parent_id_alias, cte.table[DEPTH_COLUMN] + 1])
        .from([cte.table, groups])
        .joins('LEFT OUTER JOIN cluster_groups ON cluster_groups.group_id = namespaces.id')
        .joins('LEFT OUTER JOIN clusters ON cluster_groups.cluster_id = clusters.id')
        .where(groups[:id].eq(cte.table[:group_parent_id]))
    end

    def model
      Clusters::Cluster
    end

    def clusters
      @clusters ||= model.arel_table
    end

    def groups
      @groups ||= ::Group.arel_table
    end

    def clusters_star
      @clusters_star ||= clusters[Arel.star]
    end

    def alias_as_column(value, alias_to)
      Arel::Nodes::As.new(value, Arel::Nodes::SqlLiteral.new(alias_to))
    end
  end
end
