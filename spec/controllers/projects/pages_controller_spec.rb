require 'spec_helper'

describe Projects::PagesController do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }

  let(:request_params) do
    {
      namespace_id: project.namespace,
      project_id: project
    }
  end

  before do
    allow(Gitlab.config.pages).to receive(:enabled).and_return(true)
    sign_in(user)
    project.add_master(user)
  end

  describe 'GET show' do
    it 'returns 200 status' do
      get :show, request_params

      expect(response).to have_gitlab_http_status(200)
    end

    context 'when the project is in a subgroup' do
      let(:group) { create(:group, :nested) }
      let(:project) { create(:project, namespace: group) }

      it 'returns a 404 status code' do
        get :show, request_params

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'DELETE destroy' do
    it 'returns 302 status' do
      delete :destroy, request_params

      expect(response).to have_gitlab_http_status(302)
    end
  end

  context 'pages disabled' do
    before do
      allow(Gitlab.config.pages).to receive(:enabled).and_return(false)
    end

    describe 'GET show' do
      it 'returns 404 status' do
        get :show, request_params

        expect(response).to have_gitlab_http_status(404)
      end
    end

    describe 'DELETE destroy' do
      it 'returns 404 status' do
        delete :destroy, request_params

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'PATCH update' do
    let(:request_params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        project: { pages_https_only: false }
      }
    end

    let(:update_service) { double(execute: { status: :success }) }

    before do
      allow(Projects::UpdateService).to receive(:new) { update_service }
    end

    it 'returns 302 status' do
      patch :update, request_params

      expect(response).to have_gitlab_http_status(:found)
    end

    it 'redirects back to the pages settings' do
      patch :update, request_params

      expect(response).to redirect_to(project_pages_path(project))
    end

    it 'calls the update service' do
      expect(Projects::UpdateService)
        .to receive(:new)
        .with(project, user, request_params[:project])
        .and_return(update_service)

      patch :update, request_params
    end
  end
end
