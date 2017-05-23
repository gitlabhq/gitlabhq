require 'spec_helper'

describe MetricsController do
  include StubENV

  let(:token) { current_application_settings.health_check_access_token }
  let(:json_response) { JSON.parse(response.body) }

  around do |examples|
    Dir.mktmpdir do |tmp_dir|
      @metrics_multiproc_dir = tmp_dir
      examples.run
    end
  end

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    stub_env('prometheus_multiproc_dir', @metrics_multiproc_dir)
    allow(Gitlab::Metrics).to receive(:prometheus_metrics_enabled?).and_return(true)
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

      context 'prometheus metrics are disabled' do
        before do
          allow(Gitlab::Metrics).to receive(:prometheus_metrics_enabled?).and_return(false)
        end

        it 'returns proper response' do
          get :metrics
          expect(response.status).to eq(404)
        end
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
