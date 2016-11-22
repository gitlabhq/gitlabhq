module BuildsHelper
  def sidebar_build_class(build, current_build)
    build_class = ''
    build_class += ' active' if build == current_build
    build_class += ' retried' if build.retried?
    build_class
  end

  def javascript_build_options
    {
      page_url: namespace_project_build_url(@project.namespace, @project, @build),
      build_url: namespace_project_build_url(@project.namespace, @project, @build, :json),
      build_status: @build.status,
      build_stage: @build.stage,
      log_state: @build.trace_with_state[:state].to_s
    }
  end
end
