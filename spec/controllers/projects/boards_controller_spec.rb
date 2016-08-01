require 'spec_helper'

describe Projects::BoardsController do
  let(:project) { create(:empty_project) }
  let(:user)    { create(:user) }

  before do
    project.team << [user, :master]
    sign_in(user)
  end

  describe 'GET #show' do
    it 'renders HTML template' do
      get :show, namespace_id: project.namespace.to_param, project_id: project.to_param

      expect(response).to render_template :show
      expect(response.content_type).to eq 'text/html'
    end
  end
end
