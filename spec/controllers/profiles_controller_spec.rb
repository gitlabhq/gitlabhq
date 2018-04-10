require('spec_helper')

describe ProfilesController, :request_store do
  let(:user) { create(:user) }

  describe 'PUT update' do
    it 'allows an email update from a user without an external email address' do
      sign_in(user)

      put :update,
          user: { email: "john@gmail.com", name: "John" }

      user.reload

      expect(response.status).to eq(302)
      expect(user.unconfirmed_email).to eq('john@gmail.com')
    end

    it "allows an email update without confirmation if existing verified email" do
      user = create(:user)
      create(:email, :confirmed, user: user, email: 'john@gmail.com')
      sign_in(user)

      put :update,
          user: { email: "john@gmail.com", name: "John" }

      user.reload

      expect(response.status).to eq(302)
      expect(user.unconfirmed_email).to eq nil
    end

    it 'ignores an email update from a user with an external email address' do
      stub_omniauth_setting(sync_profile_from_provider: ['ldap'])
      stub_omniauth_setting(sync_profile_attributes: true)

      ldap_user = create(:omniauth_user)
      ldap_user.create_user_synced_attributes_metadata(provider: 'ldap', name_synced: true, email_synced: true)
      sign_in(ldap_user)

      put :update,
          user: { email: "john@gmail.com", name: "John" }

      ldap_user.reload

      expect(response.status).to eq(302)
      expect(ldap_user.unconfirmed_email).not_to eq('john@gmail.com')
    end

    it 'ignores an email and name update but allows a location update from a user with external email and name, but not external location' do
      stub_omniauth_setting(sync_profile_from_provider: ['ldap'])
      stub_omniauth_setting(sync_profile_attributes: true)

      ldap_user = create(:omniauth_user, name: 'Alex')
      ldap_user.create_user_synced_attributes_metadata(provider: 'ldap', name_synced: true, email_synced: true, location_synced: false)
      sign_in(ldap_user)

      put :update,
          user: { email: "john@gmail.com", name: "John", location: "City, Country" }

      ldap_user.reload

      expect(response.status).to eq(302)
      expect(ldap_user.unconfirmed_email).not_to eq('john@gmail.com')
      expect(ldap_user.name).not_to eq('John')
      expect(ldap_user.location).to eq('City, Country')
    end
  end

  describe 'PUT update_username' do
    let(:namespace) { user.namespace }
    let(:gitlab_shell) { Gitlab::Shell.new }
    let(:new_username) { generate(:username) }

    it 'allows username change' do
      sign_in(user)

      put :update_username,
        user: { username: new_username }

      user.reload

      expect(response.status).to eq(302)
      expect(user.username).to eq(new_username)
    end

    it 'updates a username using JSON request' do
      sign_in(user)

      put :update_username,
          user: { username: new_username },
          format: :json

      expect(response.status).to eq(200)
      expect(json_response['message']).to eq('Username successfully changed')
    end

    it 'renders an error message when the username was not updated' do
      sign_in(user)

      put :update_username,
          user: { username: 'invalid username.git' },
          format: :json

      expect(response.status).to eq(422)
      expect(json_response['message']).to match(/Username change failed/)
    end

    it 'raises a correct error when the username is missing' do
      sign_in(user)

      expect { put :update_username, user: { gandalf: 'you shall not pass' } }
        .to raise_error(ActionController::ParameterMissing)
    end

    context 'with legacy storage' do
      it 'moves dependent projects to new namespace' do
        project = create(:project_empty_repo, :legacy_storage, namespace: namespace)

        sign_in(user)

        put :update_username,
          user: { username: new_username }

        user.reload

        expect(response.status).to eq(302)
        expect(gitlab_shell.exists?(project.repository_storage_path, "#{new_username}/#{project.path}.git")).to be_truthy
      end
    end

    context 'with hashed storage' do
      it 'keeps repository location unchanged on disk' do
        project = create(:project_empty_repo, namespace: namespace)

        before_disk_path = project.disk_path

        sign_in(user)

        put :update_username,
          user: { username: new_username }

        user.reload

        expect(response.status).to eq(302)
        expect(gitlab_shell.exists?(project.repository_storage_path, "#{project.disk_path}.git")).to be_truthy
        expect(before_disk_path).to eq(project.disk_path)
      end
    end
  end
end
