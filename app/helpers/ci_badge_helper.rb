module CiBadgeHelper
  def markdown_badge_code(project, ref)
    url = status_ci_project_url(project, ref: ref, format: 'png')
    "[![build status](#{url})](#{ci_project_url(project, ref: ref)})"
  end

  def html_badge_code(project, ref)
    url = status_ci_project_url(project, ref: ref, format: 'png')
    "<a href='#{ci_project_url(project, ref: ref)}'><img src='#{url}' /></a>"
  end
end
