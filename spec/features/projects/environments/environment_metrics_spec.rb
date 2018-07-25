require 'spec_helper'

describe 'Environment > Metrics' do
  include PrometheusHelpers

  let(:user) { create(:user) }
  let(:project) { create(:prometheus_project) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:build) { create(:ci_build, pipeline: pipeline) }
  let(:environment) { create(:environment, project: project) }
  let(:current_time) { Time.now.utc }

  before do
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
    it 'shows metrics' do
      click_link('See metrics')

      expect(page).to have_css('div#prometheus-graphs')
    end
  end

  def visit_environment(environment)
    visit project_environment_path(environment.project, environment)
  end
end
