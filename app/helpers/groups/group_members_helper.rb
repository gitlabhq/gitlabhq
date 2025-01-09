# frozen_string_literal: true

module Groups::GroupMembersHelper
  include AvatarsHelper

  AVATAR_SIZE = 40

  # rubocop:disable Metrics/ParameterLists -- all arguments needed
  def group_members_app_data(
    group,
    members:,
    invited:,
    access_requests:,
    banned:,
    include_relations:,
    search:,
    pending_members_count:,
    placeholder_users:
  )
    {
      user: group_members_list_data(group, members, { param_name: :page, params: { invited_members_page: nil, search_invited: nil } }),
      group: group_group_links_list_data(group, include_relations, search),
      invite: group_members_list_data(group, invited.nil? ? [] : invited, { param_name: :invited_members_page, params: { page: nil } }),
      access_request: group_members_list_data(group, access_requests.nil? ? [] : access_requests),
      source_id: group.id,
      can_manage_members: can?(current_user, :admin_group_member, group),
      can_manage_access_requests: can?(current_user, :admin_member_access_request, group),
      group_name: group.name,
      group_path: group.full_path,
      can_approve_access_requests: true, # true for CE, overridden in EE
      placeholder: placeholder_users,
      available_roles: available_group_roles(group),
      reassignment_csv_path: group_bulk_reassignment_file_path(group)
    }
  end
  # rubocop:enable Metrics/ParameterLists

  def group_member_header_subtext(group)
    ERB::Util.html_escape(_("You're viewing members of %{strong_start}%{group_name}%{strong_end}.").html_safe) % {
      group_name: group.name,
      strong_start: '<strong>'.html_safe,
      strong_end: '</strong>'.html_safe
    }
  end

  private

  def group_members_serialized(group, members)
    MemberSerializer.new.represent(members, { current_user: current_user, group: group, source: group })
  end

  def group_group_links_serialized(group, group_links)
    GroupLink::GroupGroupLinkSerializer.new.represent(group_links, { current_user: current_user, source: group })
  end

  # Overridden in `ee/app/helpers/ee/groups/group_members_helper.rb`
  def group_members_list_data(group, members, pagination = {})
    {
      members: group_members_serialized(group, members),
      pagination: members_pagination_data(members, pagination),
      member_path: group_group_member_path(group, ':id')
    }
  end

  def group_group_links(group, include_relations)
    group_links = case include_relations
                  when [:direct]
                    group.shared_with_group_links
                  when [:inherited]
                    group.shared_with_group_links_of_ancestors
                  else
                    group.shared_with_group_links_of_ancestors_and_self
                  end

    group_links.distinct_on_shared_with_group_id_with_group_access
  end

  def group_group_links_list_data(group, include_relations, search)
    group_links = group_group_links(group, include_relations)
    group_links = group_links.search(search, include_parents: true) if search

    {
      members: group_group_links_serialized(group, group_links),
      pagination: members_pagination_data(group_links),
      member_path: group_group_link_path(group, ':id')
    }
  end

  # Overridden in `ee/app/helpers/ee/groups/group_members_helper.rb`
  def available_group_roles(group)
    group.access_level_roles.sort_by { |_, access_level| access_level }.map do |name, access_level|
      { title: name, value: "static-#{access_level}" }
    end
  end
end

Groups::GroupMembersHelper.prepend_mod_with('Groups::GroupMembersHelper')
