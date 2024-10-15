# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MetricsController, :request_store do
  include StubENV

  let(:metrics_multiproc_dir) { @metrics_multiproc_dir }
  let(:whitelisted_ip) { '127.0.0.1' }
  let(:whitelisted_ip_range) { '10.0.0.0/24' }
  let(:ip_in_whitelisted_range) { '10.0.0.1' }
  let(:not_whitelisted_ip) { '10.0.1.1' }

  around do |example|
    Dir.mktmpdir do |path|
      @metrics_multiproc_dir = path
      example.run
    end
  end

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    allow(Prometheus::Client.configuration).to receive(:multiprocess_files_dir).and_return(metrics_multiproc_dir)
    allow(Gitlab::Metrics).to receive(:prometheus_metrics_enabled?).and_return(true)
    allow(Settings.monitoring).to receive(:ip_whitelist).and_return([whitelisted_ip, whitelisted_ip_range])
    allow_next_instance_of(MetricsService) do |instance|
      allow(instance).to receive(:metrics_text).and_return("prometheus_counter 1")
    end
  end

  shared_examples_for 'protected metrics endpoint' do |examples|
    context 'accessed from whitelisted ip' do
      before do
        allow(Gitlab::RequestContext.instance).to receive(:client_ip).and_return(whitelisted_ip)
      end

      it_behaves_like examples
    end

    context 'accessed from ip in whitelisted range' do
      before do
        allow(Gitlab::RequestContext.instance).to receive(:client_ip).and_return(ip_in_whitelisted_range)
      end

      it_behaves_like examples
    end

    context 'accessed from not whitelisted ip' do
      before do
        allow(Gitlab::RequestContext.instance).to receive(:client_ip).and_return(not_whitelisted_ip)
      end

      it 'returns the expected error response' do
        get :index

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe '#index' do
    shared_examples_for 'providing metrics' do
      it 'returns prometheus metrics' do
        get :index

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to match(/^prometheus_counter 1$/)
      end

      context 'prometheus metrics are disabled' do
        before do
          allow(Gitlab::Metrics).to receive(:prometheus_metrics_enabled?).and_return(false)
        end

        it 'returns proper response' do
          get :index

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).to eq("# Metrics are disabled, see: http://test.host/help/administration/monitoring/prometheus/gitlab_metrics.md#gitlab-prometheus-metrics\n")
        end
      end
    end

    include_examples 'protected metrics endpoint', 'providing metrics'
  end

  describe '#system' do
    shared_examples_for 'providing system stats' do
      let(:summary) do
        {
          version: 'ruby-3.0-patch1',
          memory_rss: 1024
        }
      end

      it 'renders system stats JSON' do
        allow(Prometheus::PidProvider).to receive(:worker_id).and_return('worker-0')
        allow(Gitlab::Metrics::System).to receive(:summary).and_return(summary)

        get :system

        expect(response).to have_gitlab_http_status(:ok)
        expect(response_json['version']).to eq('ruby-3.0-patch1')
        expect(response_json['worker_id']).to eq('worker-0')
        expect(response_json['memory_rss']).to eq(1024)
      end
    end

    include_examples 'protected metrics endpoint', 'providing system stats'
  end

  def response_json
    Gitlab::Json.parse(response.body)
  end
end
