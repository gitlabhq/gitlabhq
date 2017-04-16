module BuildsHelper
  def build_summary(build)
    if build.has_trace?
      build.trace.html(last_lines: 10).html_safe
    else
      "No job trace"
    end
  end

  def sidebar_build_class(build, current_build)
    build_class = ''
    build_class += ' active' if build.id === current_build.id
    build_class += ' retried' if build.retried?
    build_class
  end

  def javascript_build_options
    {
      page_url: namespace_project_build_url(@project.namespace, @project, @build),
      build_url: namespace_project_build_url(@project.namespace, @project, @build, :json),
      build_status: @build.status,
      build_stage: @build.stage,
      log_state: ''
    }
  end

  def build_failed_issue_options
    {
      title: "Build Failed ##{@build.id}",
      description: namespace_project_build_url(@project.namespace, @project, @build)
    }
  end
end
