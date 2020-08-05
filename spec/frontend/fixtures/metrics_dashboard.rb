# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MetricsDashboard, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers
  include MetricsDashboardHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:namespace) { create(:namespace, name: 'monitoring' )}
  let_it_be(:project) { project_with_dashboard_namespace('.gitlab/dashboards/test.yml', nil, namespace: namespace) }
  let_it_be(:environment) { create(:environment, id: 1, project: project) }
  let_it_be(:params) { { environment: environment } }

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
    allow(controller).to receive(:environment).and_return(environment)
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
