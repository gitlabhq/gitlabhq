module NavHelper
<<<<<<< HEAD
  def page_with_sidebar_class
    class_name = page_gutter_class
    class_name << 'page-with-new-sidebar' if defined?(@new_sidebar) && @new_sidebar
    class_name << 'page-with-icon-sidebar' if collapsed_sidebar? && @new_sidebar

    class_name
=======
  def page_sidebar_class
    if pinned_nav?
      "page-sidebar-expanded page-sidebar-pinned"
    end
>>>>>>> parent of aa792b91bb... Merge branch '26200-convert-sidebar-to-dropdown' into 'master'
  end

  def page_gutter_class
    if current_path?('merge_requests#show') ||
        current_path?('projects/merge_requests/conflicts#show') ||
        current_path?('issues#show') ||
        current_path?('milestones#show')
      if cookies[:collapsed_gutter] == 'true'
        %w[page-gutter right-sidebar-collapsed]
      else
        %w[page-gutter right-sidebar-expanded]
      end
    elsif current_path?('jobs#show')
      %w[page-gutter build-sidebar right-sidebar-expanded]
    elsif current_path?('wikis#show') ||
        current_path?('wikis#edit') ||
        current_path?('wikis#update') ||
        current_path?('wikis#history') ||
        current_path?('wikis#git_access')
      %w[page-gutter wiki-sidebar right-sidebar-expanded]
    else
      []
    end
  end

  def nav_header_class
    class_names = []
    class_names << 'with-horizontal-nav' if defined?(nav) && nav

<<<<<<< HEAD
    class_names
=======
    if pinned_nav?
      class_name << " header-sidebar-expanded header-sidebar-pinned"
    end

    class_name
>>>>>>> parent of aa792b91bb... Merge branch '26200-convert-sidebar-to-dropdown' into 'master'
  end

  def layout_nav_class
    return [] if show_new_nav?

    class_names = []
    class_names << 'page-with-layout-nav' if defined?(nav) && nav
    class_names << 'page-with-sub-nav' if content_for?(:sub_nav)

    class_names
  end

  def nav_control_class
    "nav-control" if current_user
  end

  def pinned_nav?
    cookies[:pin_nav] == 'true'
  end
end
