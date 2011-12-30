module ProjectsHelper
  def view_mode_style(type)
    cookies["project_view"] ||= "tile"
    cookies["project_view"] == type ? nil : "display:none"
  end

  def load_note_parent(id, type, project)
    case type
    when "Issue" then @project.issues.find(id)
    when "Commit" then @project.repo.commits(id).first
    when "Snippet" then @project.snippets.find(id)
    else
      true
    end
  rescue
    nil
  end

  def project_tab_class
    [:show, :files, :team, :edit, :update, :info].each do |action|
      return "current" if current_page?(:controller => "projects", :action => action, :id => @project)
    end

    if controller.controller_name == "snippets" || 
     controller.controller_name == "team_members"
     "current"
    end
  end

  def tree_tab_class
    current_page?(:controller => "refs",
                  :action => "tree", 
                  :project_id => @project, 
                  :id => @ref || @project.root_ref ) ? "current" : nil
  end
end
