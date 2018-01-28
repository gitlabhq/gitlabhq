require 'spec_helper'

describe Projects::Settings::RepositoryController do
  let(:project) { create(:project_empty_repo, :public) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    sign_in(user)
  end

  describe 'GET show' do
    it 'renders show with 200 status code' do
      get :show, namespace_id: project.namespace, project_id: project

      expect(response).to have_gitlab_http_status(200)
      expect(response).to render_template(:show)
    end
  end
end
