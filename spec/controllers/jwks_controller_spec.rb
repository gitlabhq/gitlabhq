# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JwksController do
  describe 'GET #index' do
    let(:ci_jwt_signing_key) { OpenSSL::PKey::RSA.generate(1024) }
    let(:ci_jwk) { ci_jwt_signing_key.to_jwk }
    let(:oidc_jwk) { OpenSSL::PKey::RSA.new(Rails.application.secrets.openid_connect_signing_key).to_jwk }

    before do
      stub_application_setting(ci_jwt_signing_key: ci_jwt_signing_key.to_s)
    end

    it 'returns signing keys used to sign CI_JOB_JWT' do
      get :index

      expect(response).to have_gitlab_http_status(:ok)

      ids = json_response['keys'].map { |jwk| jwk['kid'] }
      expect(ids).to contain_exactly(ci_jwk['kid'], oidc_jwk['kid'])
    end

    it 'does not leak private key data' do
      get :index

      aggregate_failures do
        json_response['keys'].each do |jwk|
          expect(jwk.keys).to contain_exactly('kty', 'kid', 'e', 'n', 'use', 'alg')
          expect(jwk['use']).to eq('sig')
          expect(jwk['alg']).to eq('RS256')
        end
      end
    end
  end
end
