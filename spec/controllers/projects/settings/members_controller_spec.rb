require('spec_helper')

describe Projects::Settings::MembersController do
  let(:project) { create(:empty_project, :public, :access_requestable) }

  describe 'GET show' do
    it 'renders show with 200 status code' do
      get :show, namespace_id: project.namespace, project_id: project

      expect(response).to have_http_status(200)
      expect(response).to render_template(:show)
    end
  end
end
