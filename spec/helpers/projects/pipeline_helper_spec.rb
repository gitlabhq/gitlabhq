# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::PipelineHelper do
  include Ci::BuildsHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:raw_pipeline) { create(:ci_pipeline, project: project, ref: 'master', sha: project.commit.id) }
  let_it_be(:pipeline) { Ci::PipelinePresenter.new(raw_pipeline, current_user: user)}

  describe '#js_pipeline_tabs_data' do
    before do
      project.add_developer(user)
    end

    subject(:pipeline_tabs_data) { helper.js_pipeline_tabs_data(project, pipeline, user) }

    it 'returns pipeline tabs data' do
      expect(pipeline_tabs_data).to include({
        can_generate_codequality_reports: pipeline.can_generate_codequality_reports?.to_json,
        failed_jobs_count: pipeline.failed_builds.count,
        failed_jobs_summary: prepare_failed_jobs_summary_data(pipeline.failed_builds),
        full_path: project.full_path,
        graphql_resource_etag: graphql_etag_pipeline_path(pipeline),
        metrics_path: namespace_project_ci_prometheus_metrics_histograms_path(namespace_id: project.namespace, project_id: project, format: :json),
        pipeline_iid: pipeline.iid,
        pipeline_project_path: project.full_path,
        total_job_count: pipeline.total_size
      })
    end
  end
end
