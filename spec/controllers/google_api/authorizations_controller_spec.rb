# frozen_string_literal: true

require 'spec_helper'

describe GoogleApi::AuthorizationsController do
  describe 'GET|POST #callback' do
    let(:user) { create(:user) }
    let(:token) { 'token' }
    let(:expires_at) { 1.hour.since.strftime('%s') }

    subject { get :callback, params: { code: 'xxx', state: state } }

    before do
      sign_in(user)

      allow_next_instance_of(GoogleApi::CloudPlatform::Client) do |instance|
        allow(instance).to receive(:get_token).and_return([token, expires_at])
      end
    end

    shared_examples_for 'access denied' do
      it 'returns a 404' do
        subject

        expect(session[GoogleApi::CloudPlatform::Client.session_key_for_token]).to be_nil
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'session key is present' do
      let(:session_key) { 'session-key' }
      let(:redirect_uri) { 'example.com' }

      before do
        session[GoogleApi::CloudPlatform::Client.session_key_for_redirect_uri(session_key)] = redirect_uri
      end

      context 'session key matches state param' do
        let(:state) { session_key }

        it 'sets token and expires_at in session' do
          subject

          expect(session[GoogleApi::CloudPlatform::Client.session_key_for_token])
            .to eq(token)
          expect(session[GoogleApi::CloudPlatform::Client.session_key_for_expires_at])
            .to eq(expires_at)
        end

        it 'redirects to the URL stored in state param' do
          expect(subject).to redirect_to(redirect_uri)
        end
      end

      context 'session key does not match state param' do
        let(:state) { 'bad-key' }

        it_behaves_like 'access denied'
      end

      context 'state param is blank' do
        let(:state) { '' }

        it_behaves_like 'access denied'
      end
    end

    context 'state param is present, but session key is blank' do
      let(:state) { 'session-key' }

      it_behaves_like 'access denied'
    end
  end
end
