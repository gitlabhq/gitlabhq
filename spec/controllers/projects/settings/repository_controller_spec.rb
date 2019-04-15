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
end
