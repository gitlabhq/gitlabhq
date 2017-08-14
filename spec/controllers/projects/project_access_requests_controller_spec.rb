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

  describe 'POST approve' do
    let(:current_user) { create(:user) }

    before do
      sign_in(current_user)
    end

    context 'when the given user has requested access to the project' do
      let!(:access_request) { project.request_access(user) }

      context 'when the current_user has permission to grant access to the project' do
        before do
          project.team << [current_user, :master]
        end

        it 'creates the member object' do
          post :approve, namespace_id: project.namespace,
                         project_id: project,
                         username: user.username

          expect(project.members.where(user: user)).to exist
          expect(response).to set_flash.to /User .* was granted access to the .* project./
          expect(response).to redirect_to(project_members_path(project))
        end

        it 'destroys the access request' do
          post :approve, namespace_id: project.namespace,
                         project_id: project,
                         username: user.username

          expect(project.access_requests.where(user: user)).not_to exist
        end
      end

      context 'when the current_user does not have permission to grant access to the project' do
        before do
          project.team << [current_user, :developer]
        end

        it 'responds 404 Not Found (do not reveal project existence)' do
          post :approve, namespace_id: project.namespace,
                         project_id: project,
                         username: user.username

          expect(response).to have_http_status(404)
        end

        it 'does not create any members' do
          expect do
            post :approve, namespace_id: project.namespace,
                           project_id: project,
                           username: user.username
          end.not_to change { project.members.count }
        end

        it 'does not destroy any access request' do
          expect do
            post :approve, namespace_id: project.namespace,
                           project_id: project,
                           username: user.username
          end.not_to change { project.access_requests.count }
        end
      end
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

  describe 'DELETE deny' do
    let(:current_user) { create(:user) }

    before do
      sign_in(current_user)
    end

    context 'when the given user has requested access to the project' do
      let!(:access_request) { project.request_access(user) }

      context 'when the current_user has permission to deny access to the project' do
        before do
          project.team << [current_user, :master]
        end

        it '[HTML] destroys the access request' do
          delete :deny, namespace_id: project.namespace,
                        project_id: project,
                        username: user.username

          expect(project.access_requests.where(user: user)).not_to exist
          expect(response).to set_flash.to /User .* was denied access to the .* project./
          expect(response).to redirect_to(project_members_path(project))
        end

        it '[JS] destroys the access request' do
          xhr :delete, :deny, namespace_id: project.namespace,
                              project_id: project,
                              username: user.username

          expect(project.access_requests.where(user: user)).not_to exist
          expect(response).to be_success
        end
      end

      context 'when the current_user does not have permission to deny access to the project' do
        before do
          project.team << [current_user, :developer]
        end

        it 'responds 404 Not Found (do not reveal project existence)' do
          delete :deny, namespace_id: project.namespace,
                        project_id: project,
                        username: user.username

          expect(response).to have_http_status(404)
        end

        it 'does not destroy any access request' do
          expect do
            delete :deny, namespace_id: project.namespace,
                          project_id: project,
                          username: user.username
          end.not_to change { project.access_requests.count }
        end
      end
    end
  end
end
