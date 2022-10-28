# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Settings::IntegrationsController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:namespace) { create(:namespace, name: 'frontend-fixtures') }
  let(:project)   { create(:project_empty_repo, namespace: namespace, path: 'integrations-project') }
  let!(:service)  { create(:custom_issue_tracker_integration, project: project) }
  let(:user) { project.first_owner }

  render_views

  before do
    sign_in(user)
  end

  after do
    remove_repository(project)
  end

  it 'settings/integrations/edit.html' do
    get :edit, params: {
      namespace_id: namespace,
      project_id: project,
      id: service.to_param
    }

    expect(response).to be_successful
  end
end
