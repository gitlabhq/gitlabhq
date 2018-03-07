module GroupsHelper
  def group_nav_link_paths
    %w[groups#projects groups#edit ci_cd#show ldap_group_links#index hooks#index audit_events#index pipeline_quota#index]
  end

  def group_sidebar_links
    @group_sidebar_links ||= get_group_sidebar_links
  end

  def group_sidebar_link?(link)
    group_sidebar_links.include?(link)
  end

  def can_change_group_visibility_level?(group)
    can?(current_user, :change_visibility_level, group)
  end

  def can_change_share_with_group_lock?(group)
    can?(current_user, :change_share_with_group_lock, group)
  end

  def group_issues_count(state:)
    IssuesFinder
      .new(current_user, group_id: @group.id, state: state, non_archived: true, include_subgroups: true)
      .execute
      .count
  end

  def group_merge_requests_count(state:)
    MergeRequestsFinder
      .new(current_user, group_id: @group.id, state: state, non_archived: true, include_subgroups: true)
      .execute
      .count
  end

  def group_icon(group, options = {})
    img_path = group_icon_url(group, options)
    image_tag img_path, options
  end

  def group_icon_url(group, options = {})
    if group.is_a?(String)
      group = Group.find_by_full_path(group)
    end

    group.try(:avatar_url) || ActionController::Base.helpers.image_path('no_group_avatar.png')
  end

  def group_title(group, name = nil, url = nil)
    @has_group_title = true
    full_title = ''

    group.ancestors.reverse.each_with_index do |parent, index|
      if index > 0
        add_to_breadcrumb_dropdown(group_title_link(parent, hidable: false, show_avatar: true, for_dropdown: true), location: :before)
      else
        full_title += breadcrumb_list_item group_title_link(parent, hidable: false)
      end
    end

    full_title += render "layouts/nav/breadcrumbs/collapsed_dropdown", location: :before, title: _("Show parent subgroups")

    full_title += breadcrumb_list_item group_title_link(group)
    full_title += ' &middot; '.html_safe + link_to(simple_sanitize(name), url, class: 'group-path breadcrumb-item-text js-breadcrumb-item-text') if name

    full_title.html_safe
  end

  def projects_lfs_status(group)
    lfs_status =
      if group.lfs_enabled?
        group.projects.select(&:lfs_enabled?).size
      else
        group.projects.reject(&:lfs_enabled?).size
      end

    size = group.projects.size

    if lfs_status == size
      'for all projects'
    else
      "for #{lfs_status} out of #{pluralize(size, 'project')}"
    end
  end

  def group_lfs_status(group)
    status = group.lfs_enabled? ? 'enabled' : 'disabled'

    content_tag(:span, class: "lfs-#{status}") do
      "#{status.humanize} #{projects_lfs_status(group)}"
    end
  end

  def remove_group_message(group)
    _("You are going to remove %{group_name}. Removed groups CANNOT be restored! Are you ABSOLUTELY sure?") %
      { group_name: group.name }
  end

  def share_with_group_lock_help_text(group)
    return default_help unless group.parent&.share_with_group_lock?

    if group.share_with_group_lock?
      if can?(current_user, :change_share_with_group_lock, group.parent)
        ancestor_locked_but_you_can_override(group)
      else
        ancestor_locked_so_ask_the_owner(group)
      end
    else
      ancestor_locked_and_has_been_overridden(group)
    end
  end

  def parent_group_options(current_group)
    groups = current_user.owned_groups.sort_by(&:human_name).map do |group|
      { id: group.id, text: group.human_name }
    end

    groups.delete_if { |group| group[:id] == current_group.id }
    groups.to_json
  end

  def supports_nested_groups?
    Group.supports_nested_groups?
  end

  private

  def get_group_sidebar_links
    links = [:overview, :group_members]

    if can?(current_user, :read_cross_project)
      links += [:activity, :issues, :boards, :labels, :milestones, :merge_requests]
    end

    if can?(current_user, :admin_group, @group)
      links << :settings
    end

    links
  end

  def group_title_link(group, hidable: false, show_avatar: false, for_dropdown: false)
    link_to(group_path(group), class: "group-path #{'breadcrumb-item-text' unless for_dropdown} js-breadcrumb-item-text #{'hidable' if hidable}") do
      output =
        if (group.try(:avatar_url) || show_avatar) && !Rails.env.test?
          group_icon(group, class: "avatar-tile", width: 15, height: 15)
        else
          ""
        end

      output << simple_sanitize(group.name)
      output.html_safe
    end
  end

  def ancestor_group(group)
    ancestor = oldest_consecutively_locked_ancestor(group)
    if can?(current_user, :read_group, ancestor)
      link_to ancestor.name, group_path(ancestor)
    else
      ancestor.name
    end
  end

  def remove_the_share_with_group_lock_from_ancestor(group)
    ancestor = oldest_consecutively_locked_ancestor(group)
    text = s_("GroupSettings|remove the share with group lock from %{ancestor_group_name}") % { ancestor_group_name: ancestor.name }
    if can?(current_user, :admin_group, ancestor)
      link_to text, edit_group_path(ancestor)
    else
      text
    end
  end

  def oldest_consecutively_locked_ancestor(group)
    group.ancestors.find do |group|
      !group.has_parent? || !group.parent.share_with_group_lock?
    end
  end

  def default_help
    s_("GroupSettings|This setting will be applied to all subgroups unless overridden by a group owner. Groups that already have access to the project will continue to have access unless removed manually.")
  end

  def ancestor_locked_but_you_can_override(group)
    s_("GroupSettings|This setting is applied on %{ancestor_group}. You can override the setting or %{remove_ancestor_share_with_group_lock}.").html_safe % { ancestor_group: ancestor_group(group), remove_ancestor_share_with_group_lock: remove_the_share_with_group_lock_from_ancestor(group) }
  end

  def ancestor_locked_so_ask_the_owner(group)
    s_("GroupSettings|This setting is applied on %{ancestor_group}. To share projects in this group with another group, ask the owner to override the setting or %{remove_ancestor_share_with_group_lock}.").html_safe % { ancestor_group: ancestor_group(group), remove_ancestor_share_with_group_lock: remove_the_share_with_group_lock_from_ancestor(group) }
  end

  def ancestor_locked_and_has_been_overridden(group)
    s_("GroupSettings|This setting is applied on %{ancestor_group} and has been overridden on this subgroup.").html_safe % { ancestor_group: ancestor_group(group) }
  end
end
