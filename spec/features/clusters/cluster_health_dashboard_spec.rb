# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Cluster Health board', :js, :kubeclient, :use_clean_rails_memory_store_caching, :sidekiq_inline do
  include KubernetesHelpers
  include PrometheusHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:clusterable) { create(:project) }
  let_it_be(:cluster) { create(:cluster, :provided_by_gcp, :project, projects: [clusterable]) }
  let_it_be(:cluster_path) { project_cluster_path(clusterable, cluster) }

  before do
    clusterable.add_maintainer(current_user)

    sign_in(current_user)
  end

  it 'shows cluster board section within the page' do
    visit cluster_path

    expect(page).to have_text('Health')

    click_link 'Health'

    expect(page).to have_css('.cluster-health-graphs')
  end

  context 'no prometheus available' do
    it 'shows enable Prometheus message' do
      visit cluster_path

      click_link 'Health'

      expect(page).to have_text('you must first enable Prometheus in the Integrations tab')
    end
  end

  context 'when there is cluster with enabled prometheus' do
    before do
      create(:clusters_integrations_prometheus, enabled: true, cluster: cluster)
      stub_kubeclient_discover(cluster.platform.api_url)
    end

    context 'waiting for data' do
      before do
        stub_empty_response
      end

      it 'shows container and waiting for data message' do
        visit cluster_path

        click_link 'Health'

        wait_for_requests

        expect(page).to have_css('.prometheus-graphs')
        expect(page).to have_text('Waiting for performance data')
      end
    end

    context 'connected, prometheus returns data' do
      before do
        stub_connected
      end

      it 'renders charts' do
        visit cluster_path

        click_link 'Health'

        wait_for_requests

        expect(page).to have_css('.prometheus-graphs')
        expect(page).to have_css('.prometheus-graph')
        expect(page).to have_css('.prometheus-graph-title')
        expect(page).to have_css('[_echarts_instance_]')
        expect(page).to have_content('Avg')
      end
    end

    def stub_empty_response
      stub_prometheus_request(/prometheus-prometheus-server/, status: 204, body: {})
      stub_prometheus_request(%r{prometheus/api/v1}, status: 204, body: {})
    end

    def stub_connected
      stub_prometheus_request(/prometheus-prometheus-server/, body: prometheus_values_body)
      stub_prometheus_request(%r{prometheus/api/v1}, body: prometheus_values_body)
    end
  end
end
