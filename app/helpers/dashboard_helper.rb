module DashboardHelper
  def path_to_object(project, object)
    case object.class.name.to_s
    when "Issue" then project_issues_path(project, project.issues.find(object.id))
    when "Grit::Commit" then project_commit_path(project, project.repo.commits(object.id).first)
    else "#"
    end
  end
end
