module GroupsHelper
  def can_change_group_visibility_level?(group)
    can?(current_user, :change_visibility_level, group)
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

    group.ancestors.reverse.each do |parent|
      full_title += group_title_link(parent, hidable: true)

      full_title += '<span class="hidable"> / </span>'.html_safe
    end

    full_title += group_title_link(group)
    full_title += ' &middot; '.html_safe + link_to(simple_sanitize(name), url, class: 'group-path') if name

    content_tag :span, class: 'group-title' do
      full_title.html_safe
    end
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

  def size_limit_message_for_group(group)
    show_lfs = group.lfs_enabled? ? 'and their respective LFS files' : ''

    "Repositories within this group #{show_lfs} will be restricted to this maximum size. Can be overridden inside each project. 0 for unlimited. Leave empty to inherit the global value."
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
    _("You are going to remove %{group_name}.\nRemoved groups CANNOT be restored!\nAre you ABSOLUTELY sure?") %
      { group_name: group.name }
  end

  private

  def group_title_link(group, hidable: false)
    link_to(group_path(group), class: "group-path #{'hidable' if hidable}") do
      output =
        if show_new_nav?
          image_tag(group_icon(group), class: "avatar-tile", width: 16, height: 16)
        else
          ""
        end

      output << simple_sanitize(group.name)
      output.html_safe
    end
  end
end
