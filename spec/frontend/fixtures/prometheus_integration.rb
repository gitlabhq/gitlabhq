# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Settings::IntegrationsController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:namespace) { create(:namespace, name: 'frontend-fixtures') }
  let(:project)   { create(:project_empty_repo, namespace: namespace, path: 'integrations-project') }
  let!(:integration) { create(:prometheus_integration, project: project) }
  let(:user) { project.first_owner }

  render_views

  before do
    sign_in(user)
    stub_feature_flags(remove_monitor_metrics: false)
  end

  after do
    remove_repository(project)
  end

  it 'integrations/prometheus/prometheus_integration.html' do
    get :edit, params: {
      namespace_id: namespace,
      project_id: project,
      id: integration.to_param
    }

    expect(response).to be_successful
  end
end
