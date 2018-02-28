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

    it "ignores an email update from a user with an external email address" do
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

    it "ignores an email and name update but allows a location update from a user with external email and name, but not external location" do
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
end
