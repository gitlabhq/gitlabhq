# frozen_string_literal: true

# Finder for retrieving direct group memberships of a project.
module Projects
  class ProjectGroupLinksFinder
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
    # @return [ActiveRecord::Relation] collection of ProjectGroupLink records
    def execute
      by_search(collection)
    end

    private

    attr_reader :project, :params

    def collection
      params[:max_access] ? project_group_links_max_access : group_links
    end

    def group_links
      project.project_group_links
    end

    # Returns direct memberships with highest access level.
    # Excludes direct membership if inherited membership has higher access.
    # rubocop:disable CodeReuse/ActiveRecord -- needs specialized query
    def project_group_links_max_access
      return group_links unless project.group

      inherited_access = project.group_group_links
        .select('shared_with_group_id, MAX(group_access) as max_access')
        .group(:shared_with_group_id)

      cte = Gitlab::SQL::CTE.new(:inherited_access, inherited_access, materialized: false)

      group_links
        .with(cte.to_arel)
        .joins('LEFT JOIN inherited_access ON inherited_access.shared_with_group_id = project_group_links.group_id')
        .where(
          # Uses `gteq` as project memberships takes priority
          ProjectGroupLink.arel_table[:group_access].gteq(cte.table[:max_access])
            .or(cte.table[:max_access].eq(nil))
        )
    end
    # rubocop:enable CodeReuse/ActiveRecord

    def by_search(collection)
      return collection unless params[:search]

      collection.search(params[:search])
    end
  end
end
