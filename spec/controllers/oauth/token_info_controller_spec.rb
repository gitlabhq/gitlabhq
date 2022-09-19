# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Oauth::TokenInfoController do
  describe '#show' do
    context 'when the user is not authenticated' do
      it 'responds with a 401' do
        get :show

        expect(response).to have_gitlab_http_status(:unauthorized)
        expect(Gitlab::Json.parse(response.body)).to include('error' => 'invalid_token')
      end
    end

    context 'when the request is valid' do
      let(:application) { create(:oauth_application, scopes: 'api') }
      let(:access_token) do
        create(:oauth_access_token, expires_in: 5.minutes, application: application)
      end

      it 'responds with the token info' do
        get :show, params: { access_token: access_token.token }

        expect(response).to have_gitlab_http_status(:ok)
        expect(Gitlab::Json.parse(response.body)).to eq(
          'scope' => %w[api],
          'scopes' => %w[api],
          'created_at' => access_token.created_at.to_i,
          'expires_in' => access_token.expires_in,
          'application' => { 'uid' => application.uid },
          'resource_owner_id' => access_token.resource_owner_id,
          'expires_in_seconds' => access_token.expires_in
        )
      end
    end

    context 'when the doorkeeper_token is not recognised' do
      it 'responds with a 401' do
        get :show, params: { access_token: 'unknown_token' }

        expect(response).to have_gitlab_http_status(:unauthorized)
        expect(Gitlab::Json.parse(response.body)).to include('error' => 'invalid_token')
      end
    end

    context 'when the token is expired' do
      let(:access_token) do
        create(:oauth_access_token, created_at: 2.days.ago, expires_in: 10.minutes)
      end

      it 'responds with a 401' do
        get :show, params: { access_token: access_token.token }

        expect(response).to have_gitlab_http_status(:unauthorized)
        expect(Gitlab::Json.parse(response.body)).to include('error' => 'invalid_token')
      end
    end

    context 'when the token is revoked' do
      let(:access_token) { create(:oauth_access_token, revoked_at: 2.days.ago) }

      it 'responds with a 401' do
        get :show, params: { access_token: access_token.token }

        expect(response).to have_gitlab_http_status(:unauthorized)
        expect(Gitlab::Json.parse(response.body)).to include('error' => 'invalid_token')
      end
    end
  end

  it 'includes Two-factor enforcement concern' do
    expect(described_class.included_modules.include?(EnforcesTwoFactorAuthentication)).to eq(true)
  end
end
