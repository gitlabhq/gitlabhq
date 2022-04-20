# frozen_string_literal: true

module Projects
  module PipelineHelper
    def js_pipeline_tabs_data(project, pipeline)
      {
        can_generate_codequality_reports: pipeline.can_generate_codequality_reports?.to_json,
        graphql_resource_etag: graphql_etag_pipeline_path(pipeline),
        metrics_path: namespace_project_ci_prometheus_metrics_histograms_path(namespace_id: project.namespace, project_id: project, format: :json),
        pipeline_project_path: project.full_path
      }
    end
  end
end

Projects::PipelineHelper.prepend_mod
