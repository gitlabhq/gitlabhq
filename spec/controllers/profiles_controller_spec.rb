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

    it 'ignores an email update from a user with an external email address' do
      ldap_user = create(:omniauth_user, external_email: true)
      sign_in(ldap_user)

      put :update,
          user: { email: "john@gmail.com", name: "John" }

      ldap_user.reload

      expect(response.status).to eq(302)
      expect(ldap_user.unconfirmed_email).not_to eq('john@gmail.com')
    end
  end

  describe 'PUT update_username' do
    let(:namespace) { user.namespace }
    let(:project) { create(:project_empty_repo, namespace: namespace) }
    let(:gitlab_shell) { Gitlab::Shell.new }
    let(:new_username) { 'renamedtosomethingelse' }

    it 'allows username change' do
      sign_in(user)

      put :update_username,
        user: { username: new_username }

      user.reload

      expect(response.status).to eq(302)
      expect(user.username).to eq(new_username)
    end

    it 'moves dependent projects to new namespace' do
      sign_in(user)

      put :update_username,
        user: { username: new_username }

      user.reload

      expect(response.status).to eq(302)
      expect(gitlab_shell.exists?(project.repository_storage_path, "#{new_username}/#{project.path}.git")).to be_truthy
    end
  end
end
