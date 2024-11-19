# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::PipelineHelper do
  include Ci::BuildsHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, owners: user) }
  let_it_be(:raw_pipeline) { create(:ci_pipeline, project: project, ref: 'master', sha: project.commit.id) }
  let_it_be(:pipeline) { Ci::PipelinePresenter.new(raw_pipeline, current_user: user) }

  describe '#js_pipeline_tabs_data' do
    subject(:pipeline_tabs_data) { helper.js_pipeline_tabs_data(project, pipeline, user) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    it 'returns pipeline tabs data' do
      expect(pipeline_tabs_data).to include({
        failed_jobs_count: pipeline.failed_builds.count,
        project_path: project.full_path,
        graphql_resource_etag: graphql_etag_pipeline_path(pipeline),
        metrics_path: namespace_project_ci_prometheus_metrics_histograms_path(namespace_id: project.namespace, project_id: project, format: :json),
        pipeline_iid: pipeline.iid,
        pipeline_path: pipeline_path(pipeline),
        pipeline_project_path: project.full_path,
        total_job_count: pipeline.total_size,
        summary_endpoint: summary_project_pipeline_tests_path(project, pipeline, format: :json),
        suite_endpoint: project_pipeline_test_path(project, pipeline, suite_name: 'suite', format: :json),
        blob_path: project_blob_path(project, pipeline.sha),
        has_test_report: pipeline.complete_and_has_reports?(Ci::JobArtifact.of_report_type(:test)),
        empty_state_image_path: match_asset_path('illustrations/empty-todos-md.svg'),
        artifacts_expired_image_path: match_asset_path('illustrations/empty-state/empty-pipeline-md.svg'),
        tests_count: pipeline.test_report_summary.total[:count],
        can_read_variables: true.to_s,
        manual_variables_count: pipeline.variables.count
      })
    end

    context 'when FF :ci_show_manual_variables_in_pipeline is disabled' do
      before do
        stub_feature_flags(ci_show_manual_variables_in_pipeline: false)
      end

      it 'does not include manual variables tab data' do
        expect(pipeline_tabs_data).not_to have_key(:manual_variables_count)
        expect(pipeline_tabs_data).not_to have_key(:can_read_variables)
      end
    end
  end

  describe '#js_pipeline_header_data' do
    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    subject(:pipeline_header_data) { helper.js_pipeline_header_data(project, pipeline) }

    it 'returns pipeline header data' do
      expect(pipeline_header_data).to include({
        full_path: project.full_path,
        graphql_resource_etag: graphql_etag_pipeline_path(pipeline),
        pipeline_iid: pipeline.iid,
        pipelines_path: project_pipelines_path(project)
      })
    end
  end
end
