# frozen_string_literal: true

module Ci
  module JobsHelper
    def jobs_data(project, build)
      {
        "job_endpoint" => project_job_path(project, build, format: :json),
        "log_endpoint" => trace_project_job_path(project, build, format: :json),
        "test_report_summary_url" => test_report_summary(project, build),
        "page_path" => project_job_path(project, build),
        "project_path" => project.full_path,
        "artifact_help_url" => help_page_path('user/gitlab_com/_index.md', anchor: 'gitlab-cicd'),
        "deployment_help_url" => help_page_path('user/project/clusters/deploy_to_cluster.md', anchor: 'troubleshooting'),
        "runner_settings_url" => project_runners_path(build.project, anchor: 'js-runners-settings'),
        "retry_outdated_job_docs_url" => help_page_path('ci/pipelines/settings.md', anchor: 'prevent-outdated-deployment-jobs'),
        "pipeline_test_report_url" => test_report_project_pipeline_path(project, build.pipeline),
        "log_viewer_path" => viewer_project_job_path(project, build)
      }
    end

    def job_statuses
      statuses = Ci::HasStatus::AVAILABLE_STATUSES

      statuses.index_with(&:upcase)
    end

    private

    def test_report_summary(project, build)
      return '' unless build.report_results.present?

      test_report_summary_project_job_path(project, build, format: :json)
    end
  end
end

Ci::JobsHelper.prepend_mod_with('Ci::JobsHelper')
