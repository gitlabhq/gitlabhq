module ProjectsHelper
  def view_mode_style(type)
    cookies["project_view"] ||= "tile"
    cookies["project_view"] == type ? nil : "display:none"
  end

  def remember_refs
    session[:ui] ||= {}
    session[:ui][@project.id] = { 
      :branch => params[:branch],
      :tag => params[:tag]
    }
  end
end
