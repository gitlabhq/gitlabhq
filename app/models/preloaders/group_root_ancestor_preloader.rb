# frozen_string_literal: true

module Preloaders
  class GroupRootAncestorPreloader
    def initialize(groups, root_ancestor_preloads = [])
      @groups = groups
      @root_ancestor_preloads = root_ancestor_preloads
    end

    def execute
      # type == 'Group' condition located on subquery to prevent a filter in the query
      root_query = Namespace.joins("INNER JOIN (#{join_sql}) as root_query ON root_query.root_id = namespaces.id")
                        .select('namespaces.*, root_query.id as source_id')

      root_query = root_query.preload(*@root_ancestor_preloads) if @root_ancestor_preloads.any?

      root_ancestors_by_id = root_query.group_by(&:source_id)

      @groups.each do |group|
        group.root_ancestor = root_ancestors_by_id[group.id].first
      end
    end

    private

    def join_sql
      Group.select('id, traversal_ids[1] as root_id').where(id: @groups.map(&:id)).to_sql
    end
  end
end
