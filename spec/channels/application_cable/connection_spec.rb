# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApplicationCable::Connection, :clean_gitlab_redis_shared_state do
  let(:session_id) { Rack::Session::SessionId.new('6919a6f1bb119dd7396fadc38fd18d0d') }

  before do
    Gitlab::Redis::SharedState.with do |redis|
      redis.set("session:gitlab:#{session_id.private_id}", Marshal.dump(session_hash))
    end

    cookies[Gitlab::Application.config.session_options[:key]] = session_id.public_id
  end

  context 'when user is logged in' do
    let(:user) { create(:user) }
    let(:session_hash) { { 'warden.user.user.key' => [[user.id], user.encrypted_password[0, 29]] } }

    it 'sets current_user' do
      connect

      expect(connection.current_user).to eq(user)
    end

    context 'with a stale password' do
      let(:partial_password_hash) { build(:user, password: 'some_old_password').encrypted_password[0, 29] }
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
