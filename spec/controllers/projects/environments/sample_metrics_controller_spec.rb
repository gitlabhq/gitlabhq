# frozen_string_literal: true

require 'spec_helper'

describe Projects::Environments::SampleMetricsController do
  include StubENV

  let_it_be(:project) { create(:project) }
  let_it_be(:environment) { create(:environment, project: project) }
  let_it_be(:user) { create(:user) }

  before(:context) do
    RSpec::Mocks.with_temporary_scope do
      stub_env('USE_SAMPLE_METRICS', 'true')
      Rails.application.reload_routes!
    end
  end

  after(:context) do
    Rails.application.reload_routes!
  end

  before do
    project.add_reporter(user)
    sign_in(user)
  end

  describe 'GET #query' do
    context 'when the file is not found' do
      before do
        get :query, params: environment_params
      end

      it 'returns a 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the sample data is found' do
      before do
        allow_next_instance_of(Metrics::SampleMetricsService) do |service|
          allow(service).to receive(:query).and_return([])
        end
        get :query, params: environment_params
      end

      it 'returns JSON with a message and a 200 status code' do
        expect(json_response.keys).to contain_exactly('status', 'data')
        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  private

  def environment_params(params = {})
    {
      id: environment.id.to_s,
      namespace_id: project.namespace.full_path,
      project_id: project.name,
      identifier: 'sample_metric_query_result',
      start: '2019-12-02T23:31:45.000Z',
      end: '2019-12-03T00:01:45.000Z'
    }.merge(params)
  end
end
