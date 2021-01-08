# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project Analytics (JavaScript fixtures)' do
  include ApiHelpers
  include JavaScriptFixturesHelpers

  let_it_be(:reporter) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:environment) { create(:environment, project: project, name: 'production') }

  let!(:deployments) do
    [
      1.minute.ago,
      2.days.ago,
      3.days.ago,
      3.days.ago,
      3.days.ago,
      8.days.ago,
      32.days.ago,
      91.days.ago
    ].map do |finished_at|
      create(:deployment,
        :success,
        project: project,
        environment: environment,
        finished_at: finished_at)
    end
  end

  before do
    stub_licensed_features(project_activity_analytics: true)
    project.add_reporter(reporter)
    sign_in(reporter)
  end

  after(:all) do
    remove_repository(project)
  end

  describe API::Analytics::ProjectDeploymentFrequency, type: :request do
    before(:all) do
      clean_frontend_fixtures('api/project_analytics/')
    end

    let(:shared_params) { { environment: environment.name, interval: 'daily' } }

    def make_request(additional_query_params:)
      params = shared_params.merge(additional_query_params)
      get api("/projects/#{project.id}/analytics/deployment_frequency?#{params.to_query}", reporter)
    end

    it 'api/project_analytics/daily_deployment_frequencies_for_last_week.json' do
      make_request(additional_query_params: { from: 1.week.ago })
      expect(response).to be_successful
    end

    it 'api/project_analytics/daily_deployment_frequencies_for_last_month.json' do
      make_request(additional_query_params: { from: 1.month.ago })
      expect(response).to be_successful
    end

    it 'api/project_analytics/daily_deployment_frequencies_for_last_90_days.json' do
      make_request(additional_query_params: { from: 90.days.ago })
      expect(response).to be_successful
    end
  end
end
