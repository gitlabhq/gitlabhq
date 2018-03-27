require 'spec_helper'

describe Projects::UploadsController do
  let(:model) { create(:project, :public) }
  let(:params) do
    { namespace_id: model.namespace.to_param, project_id: model }
  end

  it_behaves_like 'handle uploads'

  context 'when the URL the old style, without /-/system' do
    it 'responds with a redirect to the login page' do
      get :show, namespace_id: 'project', project_id: 'avatar', filename: 'foo.png', secret: 'bar'

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
