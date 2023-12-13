# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::DeployKeysController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers
  include AdminModeHelper

  let(:admin) { create(:admin) }
  let(:namespace) { create(:namespace, name: 'frontend-fixtures') }
  let(:project) { create(:project_empty_repo, namespace: namespace, path: 'todos-project') }
  let(:project2) { create(:project, :internal) }
  let(:project3) { create(:project, :internal) }
  let(:project4) { create(:project, :internal) }
  let(:project_key) { create(:deploy_key) }
  let(:internal_key) { create(:deploy_key) }

  before do
    # Using an admin for these fixtures because they are used for verifying a frontend
    # component that would normally get its data from `Admin::DeployKeysController`
    sign_in(admin)
    enable_admin_mode!(admin)
    create(:rsa_deploy_key_5120, public: true)
    create(:deploy_keys_project, project: project, deploy_key: project_key)
    create(:deploy_keys_project, project: project2, deploy_key: internal_key)
    create(:deploy_keys_project, project: project3, deploy_key: project_key)
    create(:deploy_keys_project, project: project4, deploy_key: project_key)
  end

  after do
    remove_repository(project)
  end

  render_views

  it 'deploy_keys/keys.json' do
    get :index, params: {
      namespace_id: project.namespace.to_param,
      project_id: project
    }, format: :json

    expect(response).to be_successful
  end

  it 'deploy_keys/enabled_keys.json' do
    get :enabled_keys, params: {
      namespace_id: project.namespace.to_param,
      project_id: project
    }, format: :json

    expect(response).to be_successful
  end

  it 'deploy_keys/available_project_keys.json' do
    get :available_project_keys, params: {
      namespace_id: project.namespace.to_param,
      project_id: project
    }, format: :json

    expect(response).to be_successful
  end

  it 'deploy_keys/available_public_keys.json' do
    get :available_public_keys, params: {
      namespace_id: project.namespace.to_param,
      project_id: project
    }, format: :json

    expect(response).to be_successful
  end
end
