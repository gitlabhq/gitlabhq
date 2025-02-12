# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApplicationCable::Channel, feature_category: :shared do
  let(:user) { create(:user) }
  let(:token) { create(:personal_access_token, user: user, scopes: [:api, :read_api]) }
  let(:channel) { described_class.new(connection, {}) }

  before do
    stub_connection current_user: user
  end

  describe '#validate_token_scope' do
    it 'validates the token scope' do
      expect(channel).to receive(:validate_and_save_access_token!)
        .with(scopes: [:api, :read_api], reset_token: true)

      channel.validate_token_scope
    end

    context 'when an authentication error occurs' do
      before do
        allow(channel).to receive(:validate_and_save_access_token!)
          .and_raise(Gitlab::Auth::AuthenticationError)
      end

      it 'handles the authentication error' do
        expect(channel).to receive(:handle_authentication_error)

        channel.validate_token_scope
      end

      context 'when client is subscribed' do
        before do
          allow(channel).to receive(:client_subscribed?).and_return(true)
        end

        it 'unsubscribes from the channel' do
          expect(channel).to receive(:unsubscribe_from_channel)

          channel.validate_token_scope
        end
      end

      context 'when client is not subscribed' do
        before do
          allow(channel).to receive(:client_subscribed?).and_return(false)
        end

        it 'rejects the subscription' do
          expect(channel).to receive(:reject)

          channel.validate_token_scope
        end
      end
    end
  end
end
