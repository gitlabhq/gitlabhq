# frozen_string_literal: true

module Ci
  module JobsHelper
    def jobs_data
      {
        "endpoint" => project_job_path(@project, @build, format: :json),
        "project_path" => @project.full_path,
        "artifact_help_url" => help_page_path('user/gitlab_com/index.md', anchor: 'gitlab-cicd'),
        "deployment_help_url" => help_page_path('user/project/clusters/deploy_to_cluster.md', anchor: 'troubleshooting'),
        "runner_settings_url" => project_runners_path(@build.project, anchor: 'js-runners-settings'),
        "page_path" => project_job_path(@project, @build),
        "build_status" => @build.status,
        "build_stage" => @build.stage_name,
        "log_state" => '',
        "build_options" => javascript_build_options,
        "retry_outdated_job_docs_url" => help_page_path('ci/pipelines/settings', anchor: 'retry-outdated-jobs')
      }
    end

    def job_statuses
      statuses = Ci::HasStatus::AVAILABLE_STATUSES

      statuses.index_with(&:upcase)
    end
  end
end

Ci::JobsHelper.prepend_mod_with('Ci::JobsHelper')
