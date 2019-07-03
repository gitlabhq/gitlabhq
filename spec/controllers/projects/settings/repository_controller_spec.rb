# frozen_string_literal: true

require 'spec_helper'

describe Projects::Settings::RepositoryController do
  let(:project) { create(:project_empty_repo, :public) }
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  describe 'GET show' do
    it 'renders show with 200 status code' do
      get :show, params: { namespace_id: project.namespace, project_id: project }

      expect(response).to have_gitlab_http_status(200)
      expect(response).to render_template(:show)
    end
  end

  describe 'PUT cleanup' do
    let(:object_map) { fixture_file_upload('spec/fixtures/bfg_object_map.txt') }

    it 'enqueues a RepositoryCleanupWorker' do
      allow(RepositoryCleanupWorker).to receive(:perform_async)

      put :cleanup, params: { namespace_id: project.namespace, project_id: project, project: { object_map: object_map } }

      expect(response).to redirect_to project_settings_repository_path(project)
      expect(RepositoryCleanupWorker).to have_received(:perform_async).once
    end
  end

  describe 'POST create_deploy_token' do
    let(:deploy_token_params) do
      {
        name: 'deployer_token',
        expires_at: 1.month.from_now.to_date.to_s,
        username: 'deployer',
        read_repository: '1'
      }
    end

    subject(:create_deploy_token) { post :create_deploy_token, params: { namespace_id: project.namespace, project_id: project, deploy_token: deploy_token_params } }

    it 'creates deploy token' do
      expect { create_deploy_token }.to change { DeployToken.active.count }.by(1)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to render_template(:show)
    end
  end
end
