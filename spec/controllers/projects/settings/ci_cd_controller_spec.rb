require('spec_helper')

describe Projects::Settings::CiCdController do
  let(:project) { create(:project, :public, :access_requestable) }
  let(:user) { create(:user) }

  before do
    project.team << [user, :master]
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
