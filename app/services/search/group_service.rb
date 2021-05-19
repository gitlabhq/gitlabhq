# frozen_string_literal: true

module Search
  class GroupService < Search::GlobalService
    attr_accessor :group

    def initialize(user, group, params)
      super(user, params)

      @group = group
    end

    def execute
      Gitlab::GroupSearchResults.new(
        current_user,
        params[:search],
        projects,
        group: group,
        order_by: params[:order_by],
        sort: params[:sort],
        filters: { state: params[:state], confidential: params[:confidential] }
      )
    end

    def projects
      return Project.none unless group
      return @projects if defined? @projects

      @projects = super.inside_path(group.full_path)
    end
  end
end

Search::GroupService.prepend_mod_with('Search::GroupService')
