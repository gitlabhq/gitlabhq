require 'spec_helper'

describe MetricsController do
  include StubENV

  let(:json_response) { JSON.parse(response.body) }
  let(:metrics_multiproc_dir) { Dir.mktmpdir }
  let(:whitelisted_ip) { '127.0.0.1' }
  let(:whitelisted_ip_range) { '10.0.0.0/24' }
  let(:ip_in_whitelisted_range) { '10.0.0.1' }
  let(:not_whitelisted_ip) { '10.0.1.1' }

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    allow(Prometheus::Client.configuration).to receive(:multiprocess_files_dir).and_return(metrics_multiproc_dir)
    allow(Gitlab::Metrics).to receive(:prometheus_metrics_enabled?).and_return(true)
    allow(Settings.monitoring).to receive(:ip_whitelist).and_return([whitelisted_ip, whitelisted_ip_range])
  end

  describe '#index' do
    shared_examples_for 'endpoint providing metrics' do
      it 'returns DB ping metrics' do
        get :index

        expect(response.body).to match(/^db_ping_timeout 0$/)
        expect(response.body).to match(/^db_ping_success 1$/)
        expect(response.body).to match(/^db_ping_latency_seconds [0-9\.]+$/)
      end

      it 'returns Redis ping metrics' do
        get :index

        expect(response.body).to match(/^redis_ping_timeout 0$/)
        expect(response.body).to match(/^redis_ping_success 1$/)
        expect(response.body).to match(/^redis_ping_latency_seconds [0-9\.]+$/)
      end

      it 'returns Caching ping metrics' do
        get :index

        expect(response.body).to match(/^redis_cache_ping_timeout 0$/)
        expect(response.body).to match(/^redis_cache_ping_success 1$/)
        expect(response.body).to match(/^redis_cache_ping_latency_seconds [0-9\.]+$/)
      end

      it 'returns Queues ping metrics' do
        get :index

        expect(response.body).to match(/^redis_queues_ping_timeout 0$/)
        expect(response.body).to match(/^redis_queues_ping_success 1$/)
        expect(response.body).to match(/^redis_queues_ping_latency_seconds [0-9\.]+$/)
      end

      it 'returns SharedState ping metrics' do
        get :index

        expect(response.body).to match(/^redis_shared_state_ping_timeout 0$/)
        expect(response.body).to match(/^redis_shared_state_ping_success 1$/)
        expect(response.body).to match(/^redis_shared_state_ping_latency_seconds [0-9\.]+$/)
      end

      context 'prometheus metrics are disabled' do
        before do
          allow(Gitlab::Metrics).to receive(:prometheus_metrics_enabled?).and_return(false)
        end

        it 'returns proper response' do
          get :index

          expect(response.status).to eq(200)
          expect(response.body).to eq("# Metrics are disabled, see: http://test.host/help/administration/monitoring/prometheus/gitlab_metrics#gitlab-prometheus-metrics\n")
        end
      end
    end

    context 'accessed from whitelisted ip' do
      before do
        allow(Gitlab::RequestContext).to receive(:client_ip).and_return(whitelisted_ip)
      end

      it_behaves_like 'endpoint providing metrics'
    end

    context 'accessed from ip in whitelisted range' do
      before do
        allow(Gitlab::RequestContext).to receive(:client_ip).and_return(ip_in_whitelisted_range)
      end

      it_behaves_like 'endpoint providing metrics'
    end

    context 'accessed from not whitelisted ip' do
      before do
        allow(Gitlab::RequestContext).to receive(:client_ip).and_return(not_whitelisted_ip)
      end

      it 'returns proper response' do
        get :index

        expect(response.status).to eq(404)
      end
    end
  end
end
