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

  def switch_colorscheme_link(opts)
    if cookies[:colorschema].blank?
      link_to_function "paint it black!", "$.cookie('colorschema','black'); window.location.reload()", opts
    else
      link_to_function "paint it white!", "$.cookie('colorschema',''); window.location.reload()", opts
    end
  end
end
