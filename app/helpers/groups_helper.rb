module GroupsHelper
  def can_change_group_visibility_level?(group)
    can?(current_user, :change_visibility_level, group)
  end

  def group_icon(group)
    if group.is_a?(String)
      group = Group.find_by(path: group)
    end

    if group && group.avatar.present?
      group.avatar.url
    else
      image_path('no_group_avatar.png')
    end
  end

  def group_title(group, name = nil, url = nil)
    full_title = link_to(simple_sanitize(group.name), group_path(group))
    full_title += ' &middot; '.html_safe + link_to(simple_sanitize(name), url) if name

    content_tag :span do
      full_title
    end
  end

  def projects_with_lfs_enabled(group, status)
    if status
      lfs_status = group.projects.select(&:lfs_enabled?).size
    else
      lfs_status = group.projects.select{ |p| !p.lfs_enabled? }.size
    end

    size = group.projects.size

    if lfs_status == size || lfs_status == 0
      'on all projects'
    else
      "on #{lfs_status} out of #{size} projects"
    end
  end

  def group_lfs_status(group)
    status = group.lfs_enabled? ? 'enabled' : 'disabled'

    content_tag(:span, class: "lfs-#{status}") do
      "#{status.humanize} #{projects_with_lfs_enabled(group, group.lfs_enabled?)}"
    end
  end
end
