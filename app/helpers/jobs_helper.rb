# frozen_string_literal: true

module JobsHelper
  def jobs_data
    {
      "endpoint" => project_job_path(@project, @build, format: :json),
      "project_path" => @project.full_path,
      "deployment_help_url" => help_page_path('user/project/clusters/index.html', anchor: 'troubleshooting-failed-deployment-jobs'),
      "runner_help_url" => help_page_path('ci/runners/README.html', anchor: 'setting-maximum-job-timeout-for-a-runner'),
      "runner_settings_url" => project_runners_path(@build.project, anchor: 'js-runners-settings'),
      "variables_settings_url" => project_variables_path(@build.project, anchor: 'js-cicd-variables-settings'),
      "page_path" => project_job_path(@project, @build),
      "build_status" => @build.status,
      "build_stage" => @build.stage,
      "log_state" => '',
      "build_options" => javascript_build_options
    }
  end
end
