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
      get :show, namespace_id: project.namespace, project_id: project

      expect(response).to have_gitlab_http_status(200)
      expect(response).to render_template(:show)
    end
  end

  describe 'PUT cleanup' do
    before do
      allow(RepositoryCleanupWorker).to receive(:perform_async)
    end

    def do_put!
      object_map = fixture_file_upload('spec/fixtures/bfg_object_map.txt')

      put :cleanup, namespace_id: project.namespace, project_id: project, project: { object_map: object_map }
    end

    context 'feature enabled' do
      it 'enqueues a RepositoryCleanupWorker' do
        stub_feature_flags(project_cleanup: true)

        do_put!

        expect(response).to redirect_to project_settings_repository_path(project)
        expect(RepositoryCleanupWorker).to have_received(:perform_async).once
      end
    end

    context 'feature disabled' do
      it 'shows a 404 error' do
        stub_feature_flags(project_cleanup: false)

        do_put!

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end
end
