# frozen_string_literal: true

require('spec_helper')

RSpec.describe ProfilesController, :request_store do
  let(:password) { User.random_password }
  let(:user) { create(:user, password: password) }

  describe 'PUT update_username' do
    let(:namespace) { user.namespace }
    let(:gitlab_shell) { Gitlab::Shell.new }
    let(:new_username) { generate(:username) }

    before do
      sign_in(user)
      allow(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_return(false)
    end

    it 'allows username change' do
      put :update_username,
        params: { user: { username: new_username } }

      user.reload

      expect(response).to have_gitlab_http_status(:found)
      expect(user.username).to eq(new_username)
    end

    it 'updates a username using JSON request' do
      put :update_username, params: { user: { username: new_username } }, format: :json

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['message']).to eq(s_('Profiles|Username successfully changed'))
    end

    it 'renders an error message when the username was not updated' do
      put :update_username, params: { user: { username: 'invalid username.git' } }, format: :json

      expect(response).to have_gitlab_http_status(:unprocessable_entity)
      expect(json_response['message']).to match(/Username change failed/)
    end

    it 'raises a correct error when the username is missing' do
      expect { put :update_username, params: { user: { gandalf: 'you shall not pass' } } }
        .to raise_error(ActionController::ParameterMissing)
    end

    context 'with hashed storage' do
      it 'keeps repository location unchanged on disk' do
        project = create(:project_empty_repo, namespace: namespace)

        before_disk_path = project.disk_path

        put :update_username,
          params: { user: { username: new_username } }

        user.reload

        expect(response).to have_gitlab_http_status(:found)
        expect(gitlab_shell.repository_exists?(project.repository_storage, "#{project.disk_path}.git")).to be_truthy
        expect(before_disk_path).to eq(project.disk_path)
      end
    end

    context 'when the rate limit is reached' do
      it 'does not update the username and returns status 429 Too Many Requests' do
        expect(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).with(:profile_update_username, scope: user).and_return(true)

        expect do
          put :update_username,
            params: { user: { username: new_username } }
        end.not_to change { user.reload.username }

        expect(response).to have_gitlab_http_status(:too_many_requests)
      end
    end
  end
end
