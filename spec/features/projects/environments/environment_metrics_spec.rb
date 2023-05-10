# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Environment > Metrics', feature_category: :projects do
  include PrometheusHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :with_prometheus_integration, :repository) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:build) { create(:ci_build, pipeline: pipeline) }
  let(:environment) { create(:environment, project: project) }
  let(:current_time) { Time.now.utc }
  let!(:staging) { create(:environment, name: 'staging', project: project) }

  before do
    project.add_developer(user)
    stub_any_prometheus_request

    sign_in(user)
    stub_feature_flags(remove_monitor_metrics: false)
  end

  around do |example|
    travel_to(current_time) { example.run }
  end

  shared_examples 'has environment selector' do
    it 'has a working environment selector', :js do
      visit_environment(environment)
      click_link 'Monitoring'

      expect(page).to have_current_path(project_metrics_dashboard_path(project, environment: environment.id))
      expect(page).to have_css('[data-testid="environments-dropdown"]')

      within('[data-testid="environments-dropdown"]') do
        # Click on the dropdown
        click_on(environment.name)

        # Select the staging environment
        click_on(staging.name)
      end

      expect(page).to have_current_path(project_metrics_dashboard_path(project, environment: staging.id))

      wait_for_requests
    end
  end

  context 'without deployments' do
    it_behaves_like 'has environment selector'
  end

  context 'with deployments and related deployable present' do
    before do
      create(:deployment, environment: environment, deployable: build)
    end

    it 'shows metrics', :js do
      visit_environment(environment)
      click_link 'Monitoring'

      expect(page).to have_css('[data-testid="prometheus-graphs"]')
    end

    it_behaves_like 'has environment selector'
  end

  def visit_environment(environment)
    visit project_environment_path(environment.project, environment)
  end
end
