module CiBadgeHelper
  def markdown_badge_code(project, ref)
    url = status_ci_project_url(project, ref: ref, format: 'png')
    link = namespace_project_commits_path(project.namespace, project, ref)
    "[![build status](#{url})](#{link})"
  end

  def html_badge_code(project, ref)
    url = status_ci_project_url(project, ref: ref, format: 'png')
    link = namespace_project_commits_path(project.namespace, project, ref)
    "<a href='#{link}'><img src='#{url}' /></a>"
  end
end
