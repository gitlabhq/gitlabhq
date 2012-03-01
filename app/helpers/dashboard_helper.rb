module DashboardHelper
  def dashboard_feed_path(project, object)
    case object.class.name.to_s
    when "Issue" then project_issue_path(project, project.issues.find(object.id))
    when "Commit" then project_commit_path(project, project.repo.commits(object.id).first)
    when "MergeRequest" then project_merge_request_path(project, object.id)
    when "Note"
      then
      note = object
      case note.noteable_type
      when "Issue" then project_issue_path(project, note.noteable_id)
      when "Snippet" then project_snippet_path(project, note.noteable_id)
      when "Commit" then project_commit_path(project, :id => note.noteable_id)
      when "MergeRequest" then project_merge_request_path(project, note.noteable_id)
      else wall_project_path(project)
      end
    else wall_project_path(project)
    end
  rescue
    "#"
  end

  def dashboard_feed_title(object)
    klass = object.class.to_s.split("::").last

    title = case klass
            when "Note" then markdown(object.note)
            when "Issue" then object.title
            when "Commit" then object.safe_message
            when "MergeRequest" then object.title
            else return "Project Wall"
            end

    truncate(sanitize(title, :tags => []), :length => 60)
  end
end
