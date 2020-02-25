# frozen_string_literal: true

require 'spec_helper'

describe 'Metrics rendering', :js, :use_clean_rails_memory_store_caching, :sidekiq_inline do
  include PrometheusHelpers
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

    allow(::Gitlab.config.gitlab)
      .to receive(:url)
      .and_return(urls.root_url.chomp('/'))

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
    end

    it 'shows embedded metrics' do
      visit project_issue_path(project, issue)

      expect(page).to have_css('div.prometheus-graph')
      expect(page).to have_text('Memory Usage (Total)')
      expect(page).to have_text('Core Usage (Total)')
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
    end

    it 'shows embedded metrics' do
      visit project_issue_path(project, issue)

      expect(page).to have_css('div.prometheus-graph')
      expect(page).to have_text('Expired / Evicted')
      expect(page).to have_text('expired - test-attribute-value')
    end
  end

  def import_common_metrics
    ::Gitlab::DatabaseImporters::CommonMetrics::Importer.new.execute
  end
end
