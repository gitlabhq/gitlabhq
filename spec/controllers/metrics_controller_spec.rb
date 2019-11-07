# frozen_string_literal: true

require 'spec_helper'

describe MetricsController do
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

  describe '#index' do
    shared_examples_for 'endpoint providing metrics' do
      it 'returns prometheus metrics' do
        get :index

        expect(response.status).to eq(200)
        expect(response.body).to match(/^prometheus_counter 1$/)
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

      it 'returns the expected error response' do
        get :index

        expect(response.status).to eq(404)
      end
    end
  end
end
