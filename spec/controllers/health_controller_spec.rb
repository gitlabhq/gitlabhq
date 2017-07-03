require 'spec_helper'

describe HealthController do
  include StubENV

  let(:json_response) { JSON.parse(response.body) }
  let(:whitelisted_ip) { '127.0.0.1' }
  let(:not_whitelisted_ip) { '127.0.0.2' }

  before do
    allow(Settings.monitoring).to receive(:ip_whitelist).and_return([IPAddr.new(whitelisted_ip)])
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
  end

  describe '#readiness' do
    context 'accessed from whitelisted ip' do
      before do
        allow(Gitlab::RequestContext).to receive(:client_ip).and_return(whitelisted_ip)
      end

      it 'returns proper response' do
        get :readiness
        expect(json_response['db_check']['status']).to eq('ok')
        expect(json_response['redis_check']['status']).to eq('ok')
        expect(json_response['fs_shards_check']['status']).to eq('ok')
        expect(json_response['fs_shards_check']['labels']['shard']).to eq('default')
      end
    end

    context 'accessed from not whitelisted ip' do
      before do
        allow(Gitlab::RequestContext).to receive(:client_ip).and_return(not_whitelisted_ip)
      end

      it 'returns proper response' do
        get :readiness
        expect(response.status).to eq(404)
      end
    end
  end

  describe '#liveness' do
    context 'accessed from whitelisted ip' do
      before do
        allow(Gitlab::RequestContext).to receive(:client_ip).and_return(whitelisted_ip)
      end

      it 'returns proper response' do
        get :liveness
        expect(json_response['db_check']['status']).to eq('ok')
        expect(json_response['redis_check']['status']).to eq('ok')
        expect(json_response['fs_shards_check']['status']).to eq('ok')
      end
    end

    context 'accessed from not whitelisted ip' do
      before do
        allow(Gitlab::RequestContext).to receive(:client_ip).and_return(not_whitelisted_ip)
      end

      it 'returns proper response' do
        get :liveness
        expect(response.status).to eq(404)
      end
    end
  end
end
