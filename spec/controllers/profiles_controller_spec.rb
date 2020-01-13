# frozen_string_literal: true

require('spec_helper')

describe ProfilesController, :request_store do
  let(:user) { create(:user) }

  describe 'POST update' do
    it 'does not update password' do
      sign_in(user)

      expect do
        post :update,
             params: { user: { password: 'hello12345', password_confirmation: 'hello12345' } }
      end.not_to change { user.reload.encrypted_password }

      expect(response.status).to eq(302)
    end
  end

  describe 'PUT update' do
    it 'allows an email update from a user without an external email address' do
      sign_in(user)

      put :update,
          params: { user: { email: "john@gmail.com", name: "John" } }

      user.reload

      expect(response.status).to eq(302)
      expect(user.unconfirmed_email).to eq('john@gmail.com')
    end

    it "allows an email update without confirmation if existing verified email" do
      user = create(:user)
      create(:email, :confirmed, user: user, email: 'john@gmail.com')
      sign_in(user)

      put :update,
          params: { user: { email: "john@gmail.com", name: "John" } }

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
          params: { user: { email: "john@gmail.com", name: "John" } }

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
          params: { user: { email: "john@gmail.com", name: "John", location: "City, Country" } }

      ldap_user.reload

      expect(response.status).to eq(302)
      expect(ldap_user.unconfirmed_email).not_to eq('john@gmail.com')
      expect(ldap_user.name).not_to eq('John')
      expect(ldap_user.location).to eq('City, Country')
    end

    context 'updating name' do
      subject { put :update, params: { user: { name: 'New Name' } } }

      context 'when the ability to update thier name is not disabled for users' do
        before do
          stub_application_setting(updating_name_disabled_for_users: false)
          sign_in(user)
        end

        it 'updates the name' do
          subject

          expect(response.status).to eq(302)
          expect(user.reload.name).to eq('New Name')
        end
      end

      context 'when the ability to update their name is disabled for users' do
        before do
          stub_application_setting(updating_name_disabled_for_users: true)
        end

        context 'as a regular user' do
          it 'does not update the name' do
            sign_in(user)

            subject

            expect(response.status).to eq(302)
            expect(user.reload.name).not_to eq('New Name')
          end
        end

        context 'as an admin user' do
          it 'updates the name' do
            admin = create(:admin)

            sign_in(admin)

            subject

            expect(response.status).to eq(302)
            expect(admin.reload.name).to eq('New Name')
          end
        end
      end
    end

    it 'allows setting a user status' do
      sign_in(user)

      put :update, params: { user: { status: { message: 'Working hard!' } } }

      expect(user.reload.status.message).to eq('Working hard!')
      expect(response).to have_gitlab_http_status(302)
    end
  end

  describe 'PUT update_username' do
    let(:namespace) { user.namespace }
    let(:gitlab_shell) { Gitlab::Shell.new }
    let(:new_username) { generate(:username) }

    it 'allows username change' do
      sign_in(user)

      put :update_username,
        params: { user: { username: new_username } }

      user.reload

      expect(response.status).to eq(302)
      expect(user.username).to eq(new_username)
    end

    it 'updates a username using JSON request' do
      sign_in(user)

      put :update_username,
          params: {
            user: { username: new_username }
          },
          format: :json

      expect(response.status).to eq(200)
      expect(json_response['message']).to eq(s_('Profiles|Username successfully changed'))
    end

    it 'renders an error message when the username was not updated' do
      sign_in(user)

      put :update_username,
          params: {
            user: { username: 'invalid username.git' }
          },
          format: :json

      expect(response.status).to eq(422)
      expect(json_response['message']).to match(/Username change failed/)
    end

    it 'raises a correct error when the username is missing' do
      sign_in(user)

      expect { put :update_username, params: { user: { gandalf: 'you shall not pass' } } }
        .to raise_error(ActionController::ParameterMissing)
    end

    context 'with legacy storage' do
      it 'moves dependent projects to new namespace' do
        project = create(:project_empty_repo, :legacy_storage, namespace: namespace)

        sign_in(user)

        put :update_username,
          params: { user: { username: new_username } }

        user.reload

        expect(response.status).to eq(302)
        expect(gitlab_shell.repository_exists?(project.repository_storage, "#{new_username}/#{project.path}.git")).to be_truthy
      end
    end

    context 'with hashed storage' do
      it 'keeps repository location unchanged on disk' do
        project = create(:project_empty_repo, namespace: namespace)

        before_disk_path = project.disk_path

        sign_in(user)

        put :update_username,
          params: { user: { username: new_username } }

        user.reload

        expect(response.status).to eq(302)
        expect(gitlab_shell.repository_exists?(project.repository_storage, "#{project.disk_path}.git")).to be_truthy
        expect(before_disk_path).to eq(project.disk_path)
      end
    end
  end
end
