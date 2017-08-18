require('spec_helper')

describe ProfilesController do
  describe "PUT update" do
    it "allows an email update from a user without an external email address" do
      user = create(:user)
      sign_in(user)

      put :update,
          user: { email: "john@gmail.com", name: "John" }

      user.reload

      expect(response.status).to eq(302)
      expect(user.unconfirmed_email).to eq('john@gmail.com')
    end

    it "ignores an email update from a user with an external email address" do
      ldap_user = create(:omniauth_user, external_email: true)
      sign_in(ldap_user)

      put :update,
          user: { email: "john@gmail.com", name: "John" }

      ldap_user.reload

      expect(response.status).to eq(302)
      expect(ldap_user.unconfirmed_email).not_to eq('john@gmail.com')
    end
  end
end
