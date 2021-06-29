# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Metrics rendering', :js, :kubeclient, :use_clean_rails_memory_store_caching, :sidekiq_inline do
  include PrometheusHelpers
  include KubernetesHelpers
  include GrafanaApiHelpers
  include MetricsDashboardUrlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:prometheus_project) }
  let_it_be(:environment) { create(:environment, project: project) }

  let(:issue) { create(:issue, project: project, description: description) }
  let(:description) { "See [metrics dashboard](#{metrics_url}) for info." }
  let(:metrics_url) { urls.metrics_project_environment_url(project, environment) }

  before do
    clear_host_from_memoized_variables
    stub_gitlab_domain

    project.add_developer(user)
    sign_in(user)
  end

  after do
    clear_host_from_memoized_variables
  end

  context 'internal metrics embeds' do
    before do
      import_common_metrics
      stub_any_prometheus_request_with_response

      allow(Prometheus::ProxyService).to receive(:new).and_call_original
    end

    it 'shows embedded metrics' do
      visit project_issue_path(project, issue)

      expect(page).to have_css('div.prometheus-graph')
      expect(page).to have_text('Memory Usage (Total)')
      expect(page).to have_text('Core Usage (Total)')

      # Ensure that the FE is calling the BE with expected params
      expect(Prometheus::ProxyService)
        .to have_received(:new)
        .with(environment, 'GET', 'query_range', hash_including('start', 'end', 'step'))
        .at_least(:once)
    end

    context 'when dashboard params are in included the url' do
      let(:metrics_url) { urls.metrics_project_environment_url(project, environment, **chart_params) }

      let(:chart_params) do
        {
          group: 'System metrics (Kubernetes)',
          title: 'Memory Usage (Pod average)',
          y_label: 'Memory Used per Pod (MB)'
        }
      end

      it 'shows embedded metrics for the specific chart' do
        visit project_issue_path(project, issue)

        expect(page).to have_css('div.prometheus-graph')
        expect(page).to have_text(chart_params[:title])
        expect(page).to have_text(chart_params[:y_label])

        # Ensure that the FE is calling the BE with expected params
        expect(Prometheus::ProxyService)
          .to have_received(:new)
          .with(environment, 'GET', 'query_range', hash_including('start', 'end', 'step'))
          .at_least(:once)
      end

      context 'when two dashboard urls are included' do
        let(:chart_params_2) do
          {
            group: 'System metrics (Kubernetes)',
            title: 'Core Usage (Total)',
            y_label: 'Total Cores'
          }
        end

        let(:metrics_url_2) { urls.metrics_project_environment_url(project, environment, **chart_params_2) }
        let(:description) { "See [metrics dashboard](#{metrics_url}) for info. \n See [metrics dashboard](#{metrics_url_2}) for info." }
        let(:issue) { create(:issue, project: project, description: description) }

        it 'shows embedded metrics for both urls' do
          visit project_issue_path(project, issue)

          expect(page).to have_css('div.prometheus-graph')
          expect(page).to have_text(chart_params[:title])
          expect(page).to have_text(chart_params[:y_label])
          expect(page).to have_text(chart_params_2[:title])
          expect(page).to have_text(chart_params_2[:y_label])

          # Ensure that the FE is calling the BE with expected params
          expect(Prometheus::ProxyService)
            .to have_received(:new)
            .with(environment, 'GET', 'query_range', hash_including('start', 'end', 'step'))
            .at_least(:once)
        end
      end
    end
  end

  context 'grafana metrics embeds' do
    let(:grafana_integration) { create(:grafana_integration, project: project) }
    let(:grafana_base_url) { grafana_integration.grafana_url }
    let(:metrics_url) { valid_grafana_dashboard_link(grafana_base_url) }

    before do
      stub_dashboard_request(grafana_base_url)
      stub_datasource_request(grafana_base_url)
      stub_all_grafana_proxy_requests(grafana_base_url)

      allow(Grafana::ProxyService).to receive(:new).and_call_original
    end

    it 'shows embedded metrics' do
      visit project_issue_path(project, issue)

      expect(page).to have_css('div.prometheus-graph')
      expect(page).to have_text('Expired / Evicted')
      expect(page).to have_text('expired - test-attribute-value')

      # Ensure that the FE is calling the BE with expected params
      expect(Grafana::ProxyService)
        .to have_received(:new)
        .with(project, anything, anything, hash_including('query', 'start', 'end', 'step'))
        .at_least(:once)
    end
  end

  context 'transient metrics embeds' do
    let(:metrics_url) { urls.metrics_dashboard_project_environment_url(project, environment, embed_json: embed_json) }
    let(:title) { 'Important Metrics' }
    let(:embed_json) do
      {
        panel_groups: [{
          panels: [{
            type: 'area-chart',
            title: title,
            y_label: 'metric',
            metrics: [{
              query_range: 'metric * 0.5 < 1'
            }]
          }]
        }]
      }.to_json
    end

    before do
      stub_any_prometheus_request_with_response
    end

    it 'shows embedded metrics' do
      visit project_issue_path(project, issue)

      expect(page).to have_css('div.prometheus-graph')
      expect(page).to have_text(title)
    end
  end

  context 'for GitLab embedded cluster health metrics' do
    before do
      project.add_maintainer(user)
      import_common_metrics
      stub_any_prometheus_request_with_response

      allow(Prometheus::ProxyService).to receive(:new).and_call_original

      create(:clusters_integrations_prometheus, cluster: cluster)
      stub_kubeclient_discover(cluster.platform.api_url)
      stub_prometheus_request(/prometheus-prometheus-server/, body: prometheus_values_body)
      stub_prometheus_request(/prometheus\/api\/v1/, body: prometheus_values_body)
    end

    let_it_be(:cluster) { create(:cluster, :provided_by_gcp, :project, projects: [project], user: user) }

    let(:params) { [project.namespace.path, project.path, cluster.id] }
    let(:query_params) { { group: 'Cluster Health', title: 'CPU Usage', y_label: 'CPU (cores)' } }
    let(:metrics_url) { urls.namespace_project_cluster_url(*params, **query_params) }
    let(:description) { "# Summary \n[](#{metrics_url})" }

    it 'shows embedded metrics' do
      visit project_issue_path(project, issue)

      expect(page).to have_css('div.prometheus-graph')
      expect(page).to have_text(query_params[:title])
      expect(page).to have_text(query_params[:y_label])
      expect(page).not_to have_text(metrics_url)

      expect(Prometheus::ProxyService)
        .to have_received(:new)
              .with(cluster, 'GET', 'query_range', hash_including('start', 'end', 'step'))
              .at_least(:once)
    end
  end

  def import_common_metrics
    ::Gitlab::DatabaseImporters::CommonMetrics::Importer.new.execute
  end
end
