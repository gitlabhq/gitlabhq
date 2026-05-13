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

    override :milestones
    def milestones
      search_term = Milestone.search(query)
      filter_milestones_by_group(search_term).order_updated_desc
    end

    def issuable_params
      super.merge(group_id: group.id, include_subgroups: true)
    end

    private

    def filter_milestones_by_group(milestones)
      candidate_projects = project_ids_relation

      candidate_projects = candidate_projects.self_and_ancestors_non_archived unless filters[:include_archived]

      authorized_projects = Project.id_in(candidate_projects).ids_with_issuables_available_for(current_user)

      authorized_groups = if filters[:include_archived]
                            group.self_and_ancestors.public_or_visible_to_user(current_user)
                          else
                            group.self_and_ancestors.non_archived.public_or_visible_to_user(current_user)
                          end

      return Milestone.none if !authorized_projects.exists? && !authorized_groups.exists?

      milestones.for_projects_and_groups(authorized_projects, authorized_groups.select(:id))
    end
  end
end

Gitlab::GroupSearchResults.prepend_mod_with('Gitlab::GroupSearchResults')
