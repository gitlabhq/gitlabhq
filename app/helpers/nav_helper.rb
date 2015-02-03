module NavHelper
  def nav_menu_collapsed?
    cookies[:collapsed_nav] == 'true'
  end
end
