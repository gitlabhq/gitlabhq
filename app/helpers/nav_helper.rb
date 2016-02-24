module NavHelper
  def nav_menu_collapsed?
    cookies[:collapsed_nav] == 'true'
  end

  def nav_sidebar_class
    if nav_menu_collapsed?
      "sidebar-collapsed"
    else
      "sidebar-expanded"
    end
  end

  def page_sidebar_class
    if nav_menu_collapsed?
      "page-sidebar-collapsed"
    else
      "page-sidebar-expanded"
    end
  end

  def page_gutter_class
    if current_path?('merge_requests#show') ||
      current_path?('merge_requests#diffs') ||
      current_path?('merge_requests#commits') ||
      current_path?('merge_requests#builds') ||
      current_path?('issues#show')
      if cookies[:collapsed_gutter] == 'true'
        "page-gutter right-sidebar-collapsed"
      else
        "page-gutter right-sidebar-expanded"
      end
    end
  end

  def nav_header_class
    if nav_menu_collapsed?
      "header-collapsed"
    else
      "header-expanded"
    end
  end
end
