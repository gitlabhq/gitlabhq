# frozen_string_literal: true

module Projects
  module PipelineHelper
    def js_pipeline_details_data(project, pipeline)
      {
        graphql_resource_etag: graphql_etag_pipeline_path(pipeline),
        metrics_path: namespace_project_ci_prometheus_metrics_histograms_path(namespace_id: project.namespace, project_id: project, format: :json),
        multi_project_help_path: help_page_path('ci/pipelines/multi_project_pipelines.md', anchor: 'multi-project-pipeline-visualization'),
        pipeline_iid: pipeline.iid,
        pipeline_project_path: project.full_path
      }
    end
  end
end
