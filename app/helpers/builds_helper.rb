module BuildsHelper
  def build_summary(build, skip: false)
    if build.has_trace?
      if skip
        link_to "View job trace", pipeline_job_url(build.pipeline, build)
      else
        build.trace.html(last_lines: 10).html_safe
      end
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
      page_path: project_job_path(@project, @build),
      build_status: @build.status,
      build_stage: @build.stage,
      log_state: ''
    }
  end

  def build_failed_issue_options
    {
      title: "Job Failed ##{@build.id}",
      description: project_job_url(@project, @build)
    }
  end
end
