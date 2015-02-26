# Shorter routing method for project and project items
module GitlabRoutingHelper
  def project_path(project, *args)
    namespace_project_path(project.namespace, project, *args)
  end

  def edit_project_path(project, *args)
    edit_namespace_project_path(project.namespace, project, *args)
  end

  def issue_path(entity, *args)
    namespace_project_issue_path(entity.project.namespace, entity.project, entity, *args)
  end

  def merge_request_path(entity, *args)
    namespace_project_merge_request_path(entity.project.namespace, entity.project, entity, *args)
  end
end
