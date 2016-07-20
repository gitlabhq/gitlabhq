module CiStatusHelper
  def ci_status_path(pipeline)
    project = pipeline.project
    builds_namespace_project_commit_path(project.namespace, project, pipeline.sha)
  end

  def ci_status_with_icon(status, target = nil)
    content = ci_icon_for_status(status) + '&nbsp;'.html_safe + ci_label_for_status(status)
    klass = "ci-status ci-#{status}"
    if target
      link_to content, target, class: klass
    else
      content_tag :span, content, class: klass
    end
  end

  def ci_label_for_status(status)
    case status
    when 'success'
      'passed'
    when 'success_with_warnings'
      'passed with warnings'
    else
      status
    end
  end

  def ci_icon_for_status(status)
    icon_name =
      case status
      when 'success'
        'icon_status_success'
      when 'success_with_warnings'
        'icon_status_warning'
      when 'failed'
        'icon_status_failed'
      when 'pending'
        'icon_status_pending'
      when 'running'
        'icon_status_running'
      else
        'icon_status_cancel'
      end

    custom_icon(icon_name)
  end

  def render_commit_status(commit, tooltip_placement: 'auto left', cssclass: '')
    project = commit.project
    path = builds_namespace_project_commit_path(project.namespace, project, commit)
    render_status_with_link('commit', commit.status, path, tooltip_placement, cssclass: cssclass)
  end

  def render_pipeline_status(pipeline, tooltip_placement: 'auto left')
    project = pipeline.project
    path = namespace_project_pipeline_path(project.namespace, project, pipeline)
    render_status_with_link('pipeline', pipeline.status, path, tooltip_placement)
  end

  def no_runners_for_project?(project)
    project.runners.blank? &&
      Ci::Runner.shared.blank?
  end

  private

  def render_status_with_link(type, status, path, tooltip_placement, cssclass: '')
    link_to ci_icon_for_status(status),
            path,
            class: "ci-status-link ci-status-icon-#{status.dasherize} #{cssclass}",
            title: "#{type.titleize}: #{ci_label_for_status(status)}",
            data: { toggle: 'tooltip', placement: tooltip_placement }
  end
end
