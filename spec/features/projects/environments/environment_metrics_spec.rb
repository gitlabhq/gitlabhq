require 'spec_helper'

feature 'Environment > Metrics' do
  include PrometheusHelpers

  given(:user) { create(:user) }
  given(:project) { create(:prometheus_project) }
  given(:pipeline) { create(:ci_pipeline, project: project) }
  given(:build) { create(:ci_build, pipeline: pipeline) }
  given(:environment) { create(:environment, project: project) }
  given(:current_time) { Time.now.utc }

  background do
    project.add_developer(user)
    create(:deployment, environment: environment, deployable: build)
    stub_all_prometheus_requests(environment.slug)

    sign_in(user)
    visit_environment(environment)
  end

  around do |example|
    Timecop.freeze(current_time) { example.run }
  end

  context 'with deployments and related deployable present' do
    scenario 'shows metrics' do
      click_link('See metrics')

      expect(page).to have_css('div#prometheus-graphs')
    end
  end

  def visit_environment(environment)
    visit project_environment_path(environment.project, environment)
  end
end
