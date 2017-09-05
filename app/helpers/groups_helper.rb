module GroupsHelper
  def can_change_group_visibility_level?(group)
    can?(current_user, :change_visibility_level, group)
  end

  def can_change_share_with_group_lock?(group)
    can?(current_user, :change_share_with_group_lock, group)
  end

  def group_icon(group)
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
        add_to_breadcrumb_dropdown(group_title_link(parent, hidable: false, show_avatar: true), location: :before)
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

  def group_issues(group)
    IssuesFinder.new(current_user, group_id: group.id).execute
  end

  def remove_group_message(group)
    _("You are going to remove %{group_name}. Removed groups CANNOT be restored! Are you ABSOLUTELY sure?") %
      { group_name: group.name }
  end

  def share_with_group_lock_help_text
    return default_help                          unless @group.has_parent?
    return default_help                          unless @group.parent.share_with_group_lock?
    return parent_locked_and_has_been_overridden unless @group.share_with_group_lock?
    return parent_locked_but_you_can_override    if     @group.has_owner?(current_user)
    return parent_locked_so_ask_the_owner
  end

  private

  def group_title_link(group, hidable: false, show_avatar: false)
    link_to(group_path(group), class: "group-path breadcrumb-item-text js-breadcrumb-item-text #{'hidable' if hidable}") do
      output =
        if (group.try(:avatar_url) || show_avatar) && !Rails.env.test?
          image_tag(group_icon(group), class: "avatar-tile", width: 15, height: 15)
        else
          ""
        end

      output << simple_sanitize(group.name)
      output.html_safe
    end
  end

  def parent_group_link
    link_to @group.parent.name, group_path(@group.parent)
  end

  def default_help
    s_("GroupSettings|This setting will be applied to all subgroups unless overridden by a group owner.")
  end

  def parent_locked_but_you_can_override
    s_("GroupSettings|This setting is applied on %{parent_group}. You can override the setting or remove the share lock from the parent group.") % { parent_group: parent_group_link }
  end

  def parent_locked_so_ask_the_owner
    s_("GroupSettings|This setting is applied on %{parent_group}. To share this group with another group, ask the owner to override the setting or remove the share lock from the parent group.") % { parent_group: parent_group_link }
  end

  def parent_locked_and_has_been_overridden
    s_("GroupSettings|This setting is applied on %{parent_group} and has been overridden on this subgroup.") % { parent_group: parent_group_link }
  end
end
