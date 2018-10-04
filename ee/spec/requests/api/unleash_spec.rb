require 'spec_helper'

describe API::Unleash do
  set(:project) { create(:project) }
  let(:project_id) { project.id }
  let(:feature_enabled) { true }
  let(:params) { }
  let(:headers) { }

  before do
    stub_licensed_features(feature_flags: feature_enabled)
  end

  shared_examples 'authenticated request' do
    context 'when using instance id' do
      let(:client) { create(:operations_feature_flags_client, project: project) }
      let(:params) { { instance_id: client.token } }

      it 'responds with OK' do
        subject

        expect(response).to have_gitlab_http_status(200)
      end

      context 'when feature is not available' do
        let(:feature_enabled) { false }

        it 'responds with forbidden' do
          subject

          expect(response).to have_gitlab_http_status(403)
        end
      end
    end

    context 'when using header' do
      let(:client) { create(:operations_feature_flags_client, project: project) }
      let(:headers) { { "UNLEASH-INSTANCEID" => client.token }}

      it 'responds with OK' do
        subject

        expect(response).to have_gitlab_http_status(200)
      end
    end

    context 'when using bogus instance id' do
      let(:params) { { instance_id: 'token' } }

      it 'responds with unauthorized' do
        subject

        expect(response).to have_gitlab_http_status(401)
      end
    end

    context 'when using not existing project' do
      let(:project_id) { -5000 }
      let(:params) { { instance_id: 'token' } }

      it 'responds with unauthorized' do
        subject

        expect(response).to have_gitlab_http_status(401)
      end
    end
  end

  describe 'GET /feature_flags/unleash/:project_id/features' do
    subject { get api("/feature_flags/unleash/#{project_id}/features"), params, headers }

    it_behaves_like 'authenticated request'

    context 'with a list of feature flag' do
      let(:client) { create(:operations_feature_flags_client, project: project) }
      let(:headers) { { "UNLEASH-INSTANCEID" => client.token }}
      let!(:enable_feature_flag) { create(:operations_feature_flag, project: project, name: 'feature1', active: true) }
      let!(:disabled_feature_flag) { create(:operations_feature_flag, project: project, name: 'feature2', active: false) }

      it 'responds with a list' do
        subject

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['version']).to eq(1)
        expect(json_response['features']).not_to be_empty
        expect(json_response['features'].first['name']).to eq('feature1')
      end

      it 'matches json schema' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('unleash/unleash', dir: 'ee')
      end
    end
  end

  describe 'POST /feature_flags/unleash/:project_id/client/register' do
    subject { post api("/feature_flags/unleash/#{project_id}/client/register"), params, headers }

    it_behaves_like 'authenticated request'
  end

  describe 'POST /feature_flags/unleash/:project_id/client/metrics' do
    subject { post api("/feature_flags/unleash/#{project_id}/client/metrics"), params, headers }

    it_behaves_like 'authenticated request'
  end
end
