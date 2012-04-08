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

  def repository_tab_class
  end

end
