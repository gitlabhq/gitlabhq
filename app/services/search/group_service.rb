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
        filters: filters
      )
    end

    def projects
      return Project.none unless group

      super.for_group_and_its_subgroups(group)
    end
    strong_memoize_attr :projects

    private

    def searched_container
      group
    end
  end
end

Search::GroupService.prepend_mod_with('Search::GroupService')
