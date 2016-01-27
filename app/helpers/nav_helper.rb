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
    if current_path?('merge_requests#show') || current_path?('issues#show')
      "page-gutter"
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
