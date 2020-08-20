# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Pipelines::TestsController do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :repository) }
  let(:pipeline) { create(:ci_pipeline, project: project) }

  before do
    sign_in(user)
  end

  describe 'GET #summary.json' do
    context 'when pipeline has build report results' do
      let(:pipeline) { create(:ci_pipeline, :with_report_results, project: project) }

      it 'renders test report summary data' do
        get_tests_summary_json

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.dig('total', 'count')).to eq(2)
      end
    end

    context 'when pipeline does not have build report results' do
      it 'renders test report summary data' do
        get_tests_summary_json

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.dig('total', 'count')).to eq(0)
      end
    end
  end

  describe 'GET #show.json' do
    context 'when pipeline has build report results' do
      let(:pipeline) { create(:ci_pipeline, :with_report_results, project: project) }
      let(:suite_name) { 'test' }
      let(:build_ids) { pipeline.latest_builds.pluck(:id) }

      it 'renders test suite data' do
        get_tests_show_json(build_ids)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['name']).to eq('test')
      end
    end

    context 'when pipeline does not have build report results' do
      let(:pipeline) { create(:ci_empty_pipeline) }
      let(:suite_name) { 'test' }

      it 'renders 404' do
        get_tests_show_json([])

        expect(response).to have_gitlab_http_status(:not_found)
        expect(response.body).to be_empty
      end
    end
  end

  def get_tests_summary_json
    get :summary,
      params: {
        namespace_id: project.namespace,
        project_id: project,
        pipeline_id: pipeline.id
      },
      format: :json
  end

  def get_tests_show_json(build_ids)
    get :show,
      params: {
        namespace_id: project.namespace,
        project_id: project,
        pipeline_id: pipeline.id,
        suite_name: suite_name,
        build_ids: build_ids
      },
      format: :json
  end
end
