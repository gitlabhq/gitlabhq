module ProjectsHelper
  def view_mode_style(type)
    cookies["project_view"] ||= "tile"
    cookies["project_view"] == type ? nil : "display:none"
  end

  def load_note_parent(id, type, project)
    case type
    when "Issue" then @project.issues.find(id)
    when "Commit" then @project.repo.commits(id).first
    else
      true
    end
  rescue 
    nil
  end
end
