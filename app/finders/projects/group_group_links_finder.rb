# frozen_string_literal: true

# Finder for retrieving inherited group memberships of a project.
module Projects
  class GroupGroupLinksFinder
    # @param project [Project] project to find memberships for
    # @param params [Hash] optional parameters
    # @option params [Boolean] :max_access when true, returns only highest access level memberships
    # @option params [String] :search filter by group namespace
    def initialize(project, params = {})
      @project = project
      @params = params
    end

    # Executes the finder and returns group links.
    #
    # @return [ActiveRecord::Relation] collection of GroupGroupLink records
    def execute
      return GroupGroupLink.none unless project.group

      by_search(collection)
    end

    private

    attr_reader :project, :params

    def collection
      params[:max_access] ? group_links_max_access : group_links
    end

    def group_links
      project.group.shared_with_group_links_of_ancestors_and_self
    end

    # Returns inherited group memberships with highest access level.
    # Excludes inherited membership if direct membership has equal/higher access.
    # rubocop:disable CodeReuse/ActiveRecord -- needs specialized query
    def group_links_max_access
      project_group_links_table = ProjectGroupLink.arel_table
      group_group_links_table = GroupGroupLink.arel_table

      join_condition = group_group_links_table
        .join(project_group_links_table, Arel::Nodes::OuterJoin)
        .on(
          project_group_links_table[:group_id].eq(group_group_links_table[:shared_with_group_id])
            .and(project_group_links_table[:project_id].eq(project.id))
        )

      distinct_subquery = project.group_group_links
        .select('DISTINCT ON (shared_with_group_id) group_group_links.*')
        .joins(join_condition.join_sources)
        .where(
          project_group_links_table[:id].eq(nil)
          # Uses `gt` only as project memberships takes priority
          .or(group_group_links_table[:group_access].gt(project_group_links_table[:group_access]))
        )
        .order(
          group_group_links_table[:shared_with_group_id].asc,
          group_group_links_table[:group_access].desc,
          group_group_links_table[:expires_at].desc,
          group_group_links_table[:created_at].asc
        )

      GroupGroupLink.from(distinct_subquery.arel.as('group_group_links'))
    end
    # rubocop:enable CodeReuse/ActiveRecord

    def by_search(collection)
      return collection unless params[:search]

      collection.search(params[:search], include_parents: true)
    end
  end
end
