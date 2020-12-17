# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Environment > Metrics' do
  include PrometheusHelpers

  let(:user) { create(:user) }
  let(:project) { create(:prometheus_project, :repository) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:build) { create(:ci_build, pipeline: pipeline) }
  let(:environment) { create(:environment, project: project) }
  let(:current_time) { Time.now.utc }
  let!(:staging) { create(:environment, name: 'staging', project: project) }

  before do
    project.add_developer(user)
    stub_any_prometheus_request

    sign_in(user)
    visit_environment(environment)
  end

  around do |example|
    travel_to(current_time) { example.run }
  end

  shared_examples 'has environment selector' do
    it 'has a working environment selector', :js do
      click_link('See metrics')

      expect(page).to have_current_path(project_metrics_dashboard_path(project, environment: environment.id))
      expect(page).to have_css('[data-qa-selector="environments_dropdown"]')

      within('[data-qa-selector="environments_dropdown"]') do
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

    it 'shows metrics' do
      click_link('See metrics')

      expect(page).to have_css('div#prometheus-graphs')
    end

    it_behaves_like 'has environment selector'
  end

  def visit_environment(environment)
    visit project_environment_path(environment.project, environment)
  end
end
