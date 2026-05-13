# frozen_string_literal: true

module Gitlab
  class GroupSearchResults < SearchResults
    extend ::Gitlab::Utils::Override

    attr_reader :group

    def initialize(current_user, query, limit_projects = nil, group:, **opts)
      @group = group
      super(
        current_user,
        query,
        limit_projects,
        default_project_filter: opts.fetch(:default_project_filter, false),
        order_by: opts.fetch(:order_by, nil),
        sort: opts.fetch(:sort, nil),
        filters: opts.fetch(:filters, {})
      )
    end

    def users
      return User.none unless Ability.allowed?(current_user, :read_group_member, group)

      groups = group.self_and_hierarchy_intersecting_with_user_groups(current_user)
      member_ids = GroupMember.of_groups(groups).non_invite.select(:user_id)

      users = super

      users.id_in(member_ids)
    end

    def issuable_params
      super.merge(group_id: group.id, include_subgroups: true)
    end
  end
end

Gitlab::GroupSearchResults.prepend_mod_with('Gitlab::GroupSearchResults')
