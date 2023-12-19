# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApplicationCable::Connection, :clean_gitlab_redis_sessions do
  include SessionHelpers

  context 'when session cookie is set' do
    before do
      stub_session(session_hash)
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
    let(:user_pat) { create(:personal_access_token) }

    it 'finds user by PAT' do
      connect(ActionCable.server.config.mount_path, headers: { Authorization: "Bearer #{user_pat.token}" })

      expect(connection.current_user).to eq(user_pat.user)
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
