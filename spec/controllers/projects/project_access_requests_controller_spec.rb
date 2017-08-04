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
end
