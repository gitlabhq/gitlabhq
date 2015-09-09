module NavHelper
  def nav_menu_collapsed?
    cookies[:collapsed_nav] == 'true'
  end

  def nav_sidebar_class
    if nav_menu_collapsed?
      "page-sidebar-collapsed"
    else
      "page-sidebar-expanded"
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
