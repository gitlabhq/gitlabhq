require('spec_helper')

describe Projects::ProjectAccessRequestsController do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, :access_requestable) }

  describe 'POST create' do
    before do
      sign_in(user)
    end

    it 'creates a ProjectAccessRequest' do
      post :create, namespace_id: project.namespace, project_id: project

      expect(response).to set_flash.to 'Your request for access has been queued for review.'
      expect(response).to redirect_to(project)
      expect(project.access_requests.exists?(user_id: user)).to be_truthy
      expect(project.users).not_to include user
    end
  end

  describe 'DELETE withdraw' do
    context 'when the current_user has requested access to the project' do
      let!(:access_request) { project.request_access(user) }

      before do
        sign_in(user)
      end

      it 'redirects with success message' do
        delete :withdraw, namespace_id: project.namespace,
                          project_id: project

        expect(response).to set_flash.to /Your access request .* has been withdrawn/
        expect(response).to redirect_to(project)
      end

      it 'destroys the access request' do
        delete :withdraw, namespace_id: project.namespace,
                          project_id: project

        expect(project.access_requests.where(user: user)).not_to exist
      end
    end

    context 'when the current_user has not requested access to the project' do
      let(:other_user) { create(:user) }
      let!(:other_access_request) { project.request_access(other_user) }

      before do
        sign_in(user)
      end

      it 'responds 404 Not Found' do
        delete :withdraw, namespace_id: project.namespace,
                          project_id: project

        expect(response).to have_http_status(404)
      end

      it "does not destroy another user's access request" do
        delete :withdraw, namespace_id: project.namespace,
                          project_id: project

        expect(project.access_requests.where(user: other_user)).to exist
      end
    end
  end

end
