# frozen_string_literal: true

require('spec_helper')

RSpec.describe UserSettings::ProfilesController, :request_store, feature_category: :user_profile do
  let(:password) { User.random_password }
  let(:user) { create(:user, password: password) }

  describe 'POST update' do
    it 'does not update password' do
      sign_in(user)
      new_password = User.random_password
      expect do
        post :update, params: { user: { password: new_password, password_confirmation: new_password } }
      end.not_to change { user.reload.encrypted_password }

      expect(response).to have_gitlab_http_status(:found)
    end

    it 'allows an email update from a user without an external email address' do
      sign_in(user)

      put :update, params: { user: { email: "john@gmail.com", name: "John", validation_password: password } }

      user.reload

      expect(response).to have_gitlab_http_status(:found)
      expect(user.unconfirmed_email).to eq('john@gmail.com')
    end

    it "allows an email update without confirmation if existing verified email" do
      user = create(:user)
      create(:email, :confirmed, user: user, email: 'john@gmail.com')
      sign_in(user)

      put :update, params: { user: { email: "john@gmail.com", name: "John" } }

      user.reload

      expect(response).to have_gitlab_http_status(:found)
      expect(user.unconfirmed_email).to eq nil
    end

    it 'ignores an email update from a user with an external email address' do
      stub_omniauth_setting(sync_profile_from_provider: ['ldap'])
      stub_omniauth_setting(sync_profile_attributes: true)

      ldap_user = create(:omniauth_user)
      ldap_user.create_user_synced_attributes_metadata(provider: 'ldap', name_synced: true, email_synced: true)
      sign_in(ldap_user)

      put :update, params: { user: { email: "john@gmail.com", name: "John" } }

      ldap_user.reload

      expect(response).to have_gitlab_http_status(:found)
      expect(ldap_user.unconfirmed_email).not_to eq('john@gmail.com')
    end

    it 'ignores an email and name update but allows a location update from a user with external email and name,' \
       'but not external location' do
      stub_omniauth_setting(sync_profile_from_provider: ['ldap'])
      stub_omniauth_setting(sync_profile_attributes: true)

      ldap_user = create(:omniauth_user, name: 'Alex')
      ldap_user.create_user_synced_attributes_metadata(
        provider: 'ldap', name_synced: true, email_synced: true, location_synced: false
      )
      sign_in(ldap_user)

      put :update, params: { user: { email: "john@gmail.com", name: "John", location: "City, Country" } }

      ldap_user.reload

      expect(response).to have_gitlab_http_status(:found)
      expect(ldap_user.unconfirmed_email).not_to eq('john@gmail.com')
      expect(ldap_user.name).not_to eq('John')
      expect(ldap_user.location).to eq('City, Country')
    end

    it 'allows setting a user status', :freeze_time do
      sign_in(user)

      put :update, params: { user: { status: {
        message: 'Working hard!', availability: 'busy', clear_status_after: '8_hours'
      } } }

      expect(user.reload.status.message).to eq('Working hard!')
      expect(user.reload.status.availability).to eq('busy')
      expect(user.reload.status.clear_status_after).to eq(8.hours.from_now)
      expect(response).to have_gitlab_http_status(:found)
    end

    it 'allows updating user specified job title' do
      title = 'Marketing Executive'
      sign_in(user)

      put :update, params: { user: { job_title: title } }

      expect(user.reload.job_title).to eq(title)
      expect(response).to have_gitlab_http_status(:found)
    end

    it 'allows updating user specified pronouns', :aggregate_failures do
      pronouns = 'they/them'
      sign_in(user)

      put :update, params: { user: { pronouns: pronouns } }

      expect(user.reload.pronouns).to eq(pronouns)
      expect(response).to have_gitlab_http_status(:found)
    end

    it 'allows updating user specified pronunciation', :aggregate_failures do
      user = create(:user, name: 'Example')
      pronunciation = 'uhg-zaam-pl'
      sign_in(user)

      put :update, params: { user: { pronunciation: pronunciation } }

      expect(user.reload.pronunciation).to eq(pronunciation)
      expect(response).to have_gitlab_http_status(:found)
    end

    it 'allows updating user specified Discord User ID', :aggregate_failures do
      discord_user_id = '1234567890123456789'
      sign_in(user)

      put :update, params: { user: { discord: discord_user_id } }

      expect(user.reload.discord).to eq(discord_user_id)
      expect(response).to have_gitlab_http_status(:found)
    end

    it 'allows updating user specified bluesky did identifier', :aggregate_failures do
      bluesky_did_id = 'did:plc:ewvi7nxzyoun6zhxrhs64oiz'
      sign_in(user)

      put :update, params: { user: { bluesky: bluesky_did_id } }

      expect(user.reload.bluesky).to eq(bluesky_did_id)
      expect(response).to have_gitlab_http_status(:found)
    end

    it 'allows updating user specified mastodon usernames with varying top level domains', :aggregate_failures do
      possible_mastodon_usernames = [
        '@robin@example.com',
        '@robin@mastadon.com',
        '@john@mastadon.social',
        '@drew@social.vivaldi.net',
        '@adil@c.im'
      ]
      sign_in(user)

      possible_mastodon_usernames.each do |mastodon_username|
        put :update, params: { user: { mastodon: mastodon_username } }

        expect(user.reload.mastodon).to eq(mastodon_username)
        expect(response).to have_gitlab_http_status(:found)
      end
    end
  end
end
