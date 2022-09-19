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
    context 'when pipeline has builds with test reports' do
      let(:main_pipeline) { create(:ci_pipeline, :with_test_reports_with_three_failures, project: project) }
      let(:pipeline) { create(:ci_pipeline, :with_test_reports_with_three_failures, project: project, ref: 'new-feature') }
      let(:suite_name) { 'test' }
      let(:build_ids) { pipeline.latest_builds.pluck(:id) }

      context 'when artifacts are expired' do
        before do
          pipeline.job_artifacts.first.update!(expire_at: Date.yesterday)
        end

        it 'renders test suite', :aggregate_failures do
          get_tests_show_json(build_ids)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['name']).to eq('test')
          expect(json_response['total_count']).to eq(3)
          expect(json_response['test_cases'].size).to eq(3)
        end
      end

      context 'when artifacts do not exist' do
        before do
          pipeline.job_artifacts.each(&:destroy)
        end

        it 'renders not_found errors', :aggregate_failures do
          get_tests_show_json(build_ids)

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['errors']).to eq('Test report artifacts not found')
        end
      end

      context 'when artifacts are not expired' do
        before do
          build = main_pipeline.builds.last
          build.update_column(:finished_at, 1.day.ago) # Just to be sure we are included in the report window

          # The JUnit fixture for the given build has 3 failures.
          # This service will create 1 test case failure record for each.
          Ci::TestFailureHistoryService.new(main_pipeline).execute
        end

        it 'renders test suite data', :aggregate_failures do
          get_tests_show_json(build_ids)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['name']).to eq('test')

          # Each test failure in this pipeline has a matching failure in the default branch
          recent_failures = json_response['test_cases'].map { |tc| tc['recent_failures'] }
          expect(recent_failures).to eq(
            [
              { 'count' => 1, 'base_branch' => 'master' },
              { 'count' => 1, 'base_branch' => 'master' },
              { 'count' => 1, 'base_branch' => 'master' }
            ])
        end
      end
    end

    context 'when pipeline has no builds that matches the given build_ids' do
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
