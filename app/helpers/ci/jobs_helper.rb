# frozen_string_literal: true

module Ci
  module JobsHelper
    def jobs_data(project, build)
      {
        "endpoint" => project_job_path(project, build, format: :json),
        "page_path" => project_job_path(project, build),
        "project_path" => project.full_path,
        "artifact_help_url" => help_page_path('user/gitlab_com/index.md', anchor: 'gitlab-cicd'),
        "deployment_help_url" => help_page_path('user/project/clusters/deploy_to_cluster.md', anchor: 'troubleshooting'),
        "runner_settings_url" => project_runners_path(build.project, anchor: 'js-runners-settings'),
        "build_status" => build.status,
        "build_stage" => build.stage_name,
        "retry_outdated_job_docs_url" => help_page_path('ci/pipelines/settings', anchor: 'retry-outdated-jobs'),
        "test_report_summary_url" => test_report_summary_project_job_path(project, build, format: :json),
        "pipeline_test_report_url" => test_report_project_pipeline_path(project, build.pipeline)
      }
    end

    def job_statuses
      statuses = Ci::HasStatus::AVAILABLE_STATUSES

      statuses.index_with(&:upcase)
    end
  end
end

Ci::JobsHelper.prepend_mod_with('Ci::JobsHelper')
