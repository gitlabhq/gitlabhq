# frozen_string_literal: true

module Ci
  module JobsHelper
    def jobs_data
      {
        "endpoint" => project_job_path(@project, @build, format: :json),
        "project_path" => @project.full_path,
        "artifact_help_url" => help_page_path('user/gitlab_com/index.html', anchor: 'gitlab-cicd'),
        "deployment_help_url" => help_page_path('user/project/clusters/index.html', anchor: 'troubleshooting'),
        "runner_settings_url" => project_runners_path(@build.project, anchor: 'js-runners-settings'),
        "page_path" => project_job_path(@project, @build),
        "build_status" => @build.status,
        "build_stage" => @build.stage,
        "log_state" => '',
        "build_options" => javascript_build_options,
        "retry_outdated_job_docs_url" => help_page_path('ci/pipelines/settings', anchor: 'retry-outdated-jobs'),
        "code_quality_help_url" => help_page_path('user/project/merge_requests/code_quality', anchor: 'troubleshooting')
      }
    end

    def job_counts
      {
        "all" => limited_counter_with_delimiter(@all_builds),
        "pending" => limited_counter_with_delimiter(@all_builds.pending),
        "running" => limited_counter_with_delimiter(@all_builds.running),
        "finished" => limited_counter_with_delimiter(@all_builds.finished)
      }
    end

    def job_statuses
      statuses = Ci::HasStatus::AVAILABLE_STATUSES

      statuses.to_h { |status| [status, status.upcase] }
    end
  end
end

Ci::JobsHelper.prepend_mod_with('Ci::JobsHelper')
