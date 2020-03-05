# frozen_string_literal: true

require 'spec_helper'

describe MetricsDashboard, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers
  include MetricsDashboardHelpers

  let(:user) { create(:user) }
  let(:project) { project_with_dashboard('.gitlab/dashboards/test.yml') }
  let(:environment) { create(:environment, project: project) }
  let(:params) { { environment: environment } }

  before(:all) do
    clean_frontend_fixtures('metrics_dashboard/')
  end

  controller(::ApplicationController) do
    include MetricsDashboard
  end

  before do
    sign_in(user)
    project.add_maintainer(user)

    allow(controller).to receive(:project).and_return(project)
    allow(controller)
        .to receive(:metrics_dashboard_params)
                .and_return(params)
  end

  after do
    remove_repository(project)
  end

  it 'metrics_dashboard/environment_metrics_dashboard.json' do
    routes.draw { get "metrics_dashboard" => "anonymous#metrics_dashboard" }
    response = get :metrics_dashboard, format: :json
    expect(response).to be_successful
  end
end
