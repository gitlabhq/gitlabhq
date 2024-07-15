# frozen_string_literal: true

module Organizations
  class GroupsFinder < GroupsFinder
    def execute
      groups = find_union(filtered_groups, Group)
      groups = groups.without_deleted

      unless default_organization?
        cte = Gitlab::SQL::CTE.new(:filtered_groups_cte, groups, materialized: false)
        groups = Group.with(cte.to_arel).from(cte.alias_to(Group.arel_table)) # rubocop: disable CodeReuse/ActiveRecord -- CTE use
      end

      sort(groups).with_route
    end

    private

    def default_organization?
      params[:organization]&.default? == true
    end

    def all_groups
      return [membership_groups, Group.none].compact if default_organization?

      super
    end

    def membership_groups
      return unless current_user

      current_user.groups.self_and_descendants
    end
  end
end
