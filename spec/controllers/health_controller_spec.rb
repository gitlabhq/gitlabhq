require 'spec_helper'

describe HealthController do
  include StubENV

  let(:token) { current_application_settings.health_check_access_token }
  let(:json_response) { JSON.parse(response.body) }

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
  end

  describe '#readiness' do
    context 'authorization token provided' do
      before do
        request.headers['TOKEN'] = token
      end

      it 'returns proper response' do
        get :readiness
        expect(json_response['db_check']['status']).to eq('ok')
        expect(json_response['cache_check']['status']).to eq('ok')
        expect(json_response['queues_check']['status']).to eq('ok')
        expect(json_response['shared_state_check']['status']).to eq('ok')
        expect(json_response['fs_shards_check']['status']).to eq('ok')
        expect(json_response['fs_shards_check']['labels']['shard']).to eq('default')
      end
    end

    context 'without authorization token' do
      it 'returns proper response' do
        get :readiness
        expect(response.status).to eq(404)
      end
    end
  end

  describe '#liveness' do
    context 'authorization token provided' do
      before do
        request.headers['TOKEN'] = token
      end

      it 'returns proper response' do
        get :liveness
        expect(json_response['db_check']['status']).to eq('ok')
        expect(json_response['cache_check']['status']).to eq('ok')
        expect(json_response['queues_check']['status']).to eq('ok')
        expect(json_response['shared_state_check']['status']).to eq('ok')
        expect(json_response['fs_shards_check']['status']).to eq('ok')
      end
    end

    context 'without authorization token' do
      it 'returns proper response' do
        get :liveness
        expect(response.status).to eq(404)
      end
    end
  end
end
