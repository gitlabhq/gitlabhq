# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApplicationCable::Channel, feature_category: :shared do
  let_it_be(:user) { create(:user) }

  let(:channel) { described_class.new(connection, {}) }

  describe '#validate_user_authorization' do
    before do
      stub_action_cable_connection current_user: user
    end

    it 'validates the token scope and access_api permissions' do
      expect(Ability).to receive(:allowed?)
        .with(user, :access_api)
        .and_return(true)

      expect(channel).to receive(:validate_and_save_access_token!)
        .with(scopes: [:api, :read_api], reset_token: true)

      channel.validate_user_authorization
    end

    context 'when an authentication error occurs' do
      before do
        allow(channel).to receive(:validate_and_save_access_token!)
          .and_raise(Gitlab::Auth::AuthenticationError)
      end

      it 'handles the authentication error' do
        expect(channel).to receive(:handle_authentication_error)

        channel.validate_user_authorization
      end

      context 'when client is subscribed' do
        before do
          allow(channel).to receive(:client_subscribed?).and_return(true)
        end

        it 'unsubscribes from the channel' do
          expect(channel).to receive(:unsubscribe_from_channel)

          channel.validate_user_authorization
        end
      end

      context 'when client is not subscribed' do
        before do
          allow(channel).to receive(:client_subscribed?).and_return(false)
        end

        it 'rejects the subscription' do
          expect(channel).to receive(:reject)

          channel.validate_user_authorization
        end
      end
    end
  end

  describe '#subscribe' do
    before do
      stub_action_cable_connection current_user: current_user

      subscribe
    end

    context 'when not logged in' do
      let(:current_user) { nil }

      it 'allows the subscription' do
        expect(subscription).to be_confirmed
      end
    end

    context 'when user is active' do
      let(:current_user) { user }

      it 'allows the subscription' do
        expect(subscription).to be_confirmed
      end
    end

    context 'when user is blocked' do
      let(:current_user) { create(:user, :blocked) }

      it 'rejects the subscription' do
        expect(subscription).not_to be_confirmed
      end
    end
  end
end
