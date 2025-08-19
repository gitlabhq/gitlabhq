# frozen_string_literal: true

module Projects
  module PipelineHelper
    extend ::Ci::BuildsHelper

    def js_pipeline_tabs_data(project, pipeline, _user)
      {
        failed_jobs_count: pipeline.failed_builds.count,
        project_path: project.full_path,
        graphql_resource_etag: graphql_etag_pipeline_path(pipeline),
        metrics_path: namespace_project_ci_prometheus_metrics_histograms_path(
          namespace_id: project.namespace,
          project_id: project,
          format: :json
        ),
        pipeline_iid: pipeline.iid,
        pipeline_path: pipeline_path(pipeline),
        pipeline_project_path: project.full_path,
        total_job_count: pipeline.total_size,
        summary_endpoint: summary_project_pipeline_tests_path(project, pipeline, format: :json),
        suite_endpoint: project_pipeline_test_path(project, pipeline, suite_name: 'suite', format: :json),
        blob_path: project_blob_path(project, pipeline.sha),
        has_test_report: pipeline.has_test_reports?,
        empty_state_image_path: image_path('illustrations/empty-todos-md.svg'),
        artifacts_expired_image_path: image_path('illustrations/empty-state/empty-pipeline-md.svg'),
        tests_count: pipeline.test_report_summary.total[:count],
        manual_variables_count: pipeline.variables.count,
        can_read_variables: can?(current_user, :read_pipeline_variable, pipeline).to_s,
        display_pipeline_variables: pipeline.project.ci_display_pipeline_variables?.to_s
      }
    end

    def js_pipeline_header_data(project, pipeline)
      {
        full_path: project.full_path,
        graphql_resource_etag: graphql_etag_pipeline_path(pipeline),
        pipeline_iid: pipeline.iid,
        pipelines_path: project_pipelines_path(project)
      }
    end
  end
end

Projects::PipelineHelper.prepend_mod
