# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GoogleApi::AuthorizationsController do
  describe 'GET|POST #callback' do
    let(:user) { create(:user) }
    let(:token) { 'token' }
    let(:expires_at) { 1.hour.since.strftime('%s') }

    subject { get :callback, params: { code: 'xxx', state: state } }

    before do
      sign_in(user)
    end

    shared_examples_for 'access denied' do
      it 'returns a 404' do
        subject

        expect(session[GoogleApi::CloudPlatform::Client.session_key_for_token]).to be_nil
        expect(response).to have_gitlab_http_status(:not_found)
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

        before do
          allow_next_instance_of(GoogleApi::CloudPlatform::Client) do |instance|
            allow(instance).to receive(:get_token).and_return([token, expires_at])
          end
        end

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

      context 'when a Faraday exception occurs' do
        let(:state) { session_key }

        [::Faraday::TimeoutError, ::Faraday::ConnectionFailed].each do |error|
          it "sets a flash alert on #{error}" do
            allow_next_instance_of(GoogleApi::CloudPlatform::Client) do |instance|
              allow(instance).to receive(:get_token).and_raise(error.new(nil))
            end

            subject

            expect(flash[:alert]).to eq('Timeout connecting to the Google API. Please try again.')
          end
        end
      end
    end

    context 'state param is present, but session key is blank' do
      let(:state) { 'session-key' }

      it_behaves_like 'access denied'
    end

    context 'user logs in but declines authorizations' do
      subject { get :callback, params: { error: 'xxx', state: state } }

      let(:session_key) { 'session-key' }
      let(:redirect_uri) { 'example.com' }
      let(:error_uri) { 'error.com' }
      let(:state) { session_key }

      before do
        session[GoogleApi::CloudPlatform::Client.session_key_for_redirect_uri(session_key)] = redirect_uri
        session[:error_uri] = error_uri
        allow_next_instance_of(GoogleApi::CloudPlatform::Client) do |instance|
          allow(instance).to receive(:get_token).and_return([token, expires_at])
        end
      end

      it 'redirects to error uri' do
        expect(subject).to redirect_to(error_uri)
      end
    end
  end
end
