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
    [:show, :files, :team, :edit, :update].each do |action|
      return "current" if current_page?(:controller => "projects", :action => action, :id => @project)
    end

    if controller.controller_name == "snippets" || 
     controller.controller_name == "team_members"
     "current"
    end
  end

  def tree_tab_class
    controller.controller_name == "refs" ? 
     "current" : nil
  end

  def repository_tab_class
    if controller.controller_name == "repositories" ||
      controller.controller_name == "hooks"
     "current"
    end
  end
end
