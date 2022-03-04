# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::PipelineHelper do
  describe '#js_pipeline_details_data' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:pipeline) { create(:ci_pipeline, project: project, ref: 'master', sha: project.commit.id) }

    subject(:pipeline_details_data) { helper.js_pipeline_details_data(project, pipeline) }

    it 'returns pipeline details data' do
      expect(pipeline_details_data).to eq({
        graphql_resource_etag: graphql_etag_pipeline_path(pipeline),
        metrics_path: namespace_project_ci_prometheus_metrics_histograms_path(namespace_id: project.namespace, project_id: project, format: :json),
        multi_project_help_path: help_page_path('ci/pipelines/multi_project_pipelines.md', anchor: 'multi-project-pipeline-visualization'),
        pipeline_iid: pipeline.iid,
        pipeline_project_path: project.full_path
      })
    end
  end
end
