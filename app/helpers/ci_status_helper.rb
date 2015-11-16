module CiStatusHelper
  def ci_status_path(ci_commit)
    project = ci_commit.gl_project
    builds_namespace_project_commit_path(project.namespace, project, ci_commit.sha)
  end

  def ci_status_icon(ci_commit)
    ci_icon_for_status(ci_commit.status)
  end

  def ci_status_color(ci_commit)
    case ci_commit.status
    when 'success'
      'green'
    when 'failed'
      'red'
    when 'running', 'pending'
      'yellow'
    else
      'gray'
    end
  end

  def ci_status_with_icon(status)
    content_tag :span, class: "ci-status ci-#{status}" do
      ci_icon_for_status(status) + '&nbsp;'.html_safe + status
    end
  end

  def ci_icon_for_status(status)
    icon_name =
      case status
      when 'success'
        'check'
      when 'failed'
        'close'
      when 'running', 'pending'
        'clock-o'
      else
        'circle'
      end

    icon(icon_name)
  end

  def render_ci_status(ci_commit)
    link_to ci_status_path(ci_commit),
      class: "c#{ci_status_color(ci_commit)}",
      title: "Build status: #{ci_commit.status}",
      data: { toggle: 'tooltip', placement: 'left' } do
      ci_status_icon(ci_commit)
    end
  end
end
