# frozen_string_literal: true

require 'spec_helper'

describe 'Metrics rendering', :js, :use_clean_rails_memory_store_caching do
  include PrometheusHelpers

  let(:user) { create(:user) }
  let(:project) { create(:prometheus_project) }
  let(:environment) { create(:environment, project: project) }
  let(:issue) { create(:issue, project: project, description: description) }
  let(:description) { "See [metrics dashboard](#{metrics_url}) for info." }
  let(:metrics_url) { metrics_project_environment_url(project, environment) }

  before do
    configure_host
    import_common_metrics
    stub_any_prometheus_request_with_response

    project.add_developer(user)

    sign_in(user)
  end

  after do
    restore_host
  end

  context 'with deployments and related deployable present' do
    it 'shows embedded metrics' do
      visit project_issue_path(project, issue)

      expect(page).to have_css('div.prometheus-graph')
      expect(page).to have_text('Memory Usage (Total)')
      expect(page).to have_text('Core Usage (Total)')
    end
  end

  def import_common_metrics
    ::Gitlab::DatabaseImporters::CommonMetrics::Importer.new.execute
  end

  def configure_host
    @original_default_host = default_url_options[:host]
    @original_gitlab_url = Gitlab.config.gitlab[:url]

    # Ensure we create a metrics url with the right host.
    # Configure host for route helpers in specs (also updates root_url):
    default_url_options[:host] = Capybara.server_host

    # Ensure we identify urls with the appropriate host.
    # Configure host to include port in app:
    Gitlab.config.gitlab[:url] = root_url.chomp('/')
  end

  def restore_host
    default_url_options[:host] = @original_default_host
    Gitlab.config.gitlab[:url] = @original_gitlab_url
  end
end
