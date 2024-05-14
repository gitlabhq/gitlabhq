# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApplicationCable::Connection, :clean_gitlab_redis_sessions do
  include SessionHelpers

  context 'when session cookie is set' do
    before do
      stub_session(session_data: session_hash)
    end

    context 'when user is logged in' do
      let(:user) { create(:user) }
      let(:session_hash) { { 'warden.user.user.key' => [[user.id], user.authenticatable_salt] } }

      it 'sets current_user' do
        connect

        expect(connection.current_user).to eq(user)
      end

      context 'with a stale password' do
        let(:partial_password_hash) { build(:user, password: User.random_password).authenticatable_salt }
        let(:session_hash) { { 'warden.user.user.key' => [[user.id], partial_password_hash] } }

        it 'sets current_user to nil' do
          connect

          expect(connection.current_user).to be_nil
        end
      end
    end

    context 'when user is not logged in' do
      let(:session_hash) { {} }

      it 'sets current_user to nil' do
        connect

        expect(connection.current_user).to be_nil
      end
    end
  end

  context 'when bearer header is provided' do
    context 'when it is a personal_access_token' do
      let(:user_pat) { create(:personal_access_token) }

      it 'finds user by PAT' do
        connect(ActionCable.server.config.mount_path, headers: { Authorization: "Bearer #{user_pat.token}" })

        expect(connection.current_user).to eq(user_pat.user)
      end
    end

    context 'when it is an OAuth access token' do
      context 'when it is a valid OAuth access token' do
        let(:user) { create(:user) }

        let(:application) do
          Doorkeeper::Application.create!(name: "MyApp", redirect_uri: "https://app.com", owner: user)
        end

        let(:oauth_token) do
          create(:oauth_access_token,
            application_id: application.id,
            resource_owner_id: user.id,
            scopes: "api"
          )
        end

        it 'finds user by OAuth access token' do
          connect(ActionCable.server.config.mount_path, headers: {
            'Authorization' => "Bearer #{oauth_token.plaintext_token}"
          })

          expect(connection.current_user).to eq(oauth_token.user)
        end
      end

      context 'when it is an invalid OAuth access token' do
        it 'sets the current_user as `nil`, and rejects the connection' do
          expect do
            connect(ActionCable.server.config.mount_path, headers: {
              'Authorization' => "Bearer invalid_token"
            })
          end.to have_rejected_connection

          expect(connection.current_user).to be_nil
        end
      end
    end
  end

  context 'when session cookie is not set' do
    it 'sets current_user to nil' do
      connect

      expect(connection.current_user).to be_nil
    end
  end

  context 'when session cookie is an empty string' do
    it 'sets current_user to nil' do
      cookies[Gitlab::Application.config.session_options[:key]] = ''

      connect

      expect(connection.current_user).to be_nil
    end
  end
end
