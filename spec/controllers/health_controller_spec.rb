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
        expect(json_response['redis_check']['status']).to eq('ok')
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
        expect(json_response['redis_check']['status']).to eq('ok')
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

  describe '#metrics' do
    context 'authorization token provided' do
      before do
        request.headers['TOKEN'] = token
      end

      it 'returns DB ping metrics' do
        get :metrics
        expect(response.body).to match(/^db_ping_timeout 0$/)
        expect(response.body).to match(/^db_ping_success 1$/)
        expect(response.body).to match(/^db_ping_latency [0-9\.]+$/)
      end

      it 'returns Redis ping metrics' do
        get :metrics
        expect(response.body).to match(/^redis_ping_timeout 0$/)
        expect(response.body).to match(/^redis_ping_success 1$/)
        expect(response.body).to match(/^redis_ping_latency [0-9\.]+$/)
      end

      it 'returns file system check metrics' do
        get :metrics
        expect(response.body).to match(/^filesystem_access_latency{shard="default"} [0-9\.]+$/)
        expect(response.body).to match(/^filesystem_accessible{shard="default"} 1$/)
        expect(response.body).to match(/^filesystem_write_latency{shard="default"} [0-9\.]+$/)
        expect(response.body).to match(/^filesystem_writable{shard="default"} 1$/)
        expect(response.body).to match(/^filesystem_read_latency{shard="default"} [0-9\.]+$/)
        expect(response.body).to match(/^filesystem_readable{shard="default"} 1$/)
      end
    end

    context 'without authorization token' do
      it 'returns proper response' do
        get :metrics
        expect(response.status).to eq(404)
      end
    end
  end
end
