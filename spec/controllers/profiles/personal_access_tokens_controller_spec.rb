# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Profiles::PersonalAccessTokensController do
  let(:user) { create(:user) }
  let(:token_attributes) { attributes_for(:personal_access_token) }

  before do
    sign_in(user)
  end

  describe '#create' do
    def created_token
      PersonalAccessToken.order(:created_at).last
    end

    it "allows creation of a token with scopes" do
      name = 'My PAT'
      scopes = %w[api read_user]

      post :create, params: { personal_access_token: token_attributes.merge(scopes: scopes, name: name) }

      expect(created_token).not_to be_nil
      expect(created_token.name).to eq(name)
      expect(created_token.scopes).to eq(scopes)
      expect(PersonalAccessToken.active).to include(created_token)
    end

    it "allows creation of a token with an expiry date" do
      expires_at = 5.days.from_now.to_date

      post :create, params: { personal_access_token: token_attributes.merge(expires_at: expires_at) }

      expect(created_token).not_to be_nil
      expect(created_token.expires_at).to eq(expires_at)
    end
  end

  describe '#index' do
    let!(:active_personal_access_token) { create(:personal_access_token, user: user) }

    before do
      # Impersonation and inactive personal tokens are ignored
      create(:personal_access_token, :impersonation, user: user)
      create(:personal_access_token, :revoked, user: user)
      get :index
    end

    it "only includes details of the active personal access token" do
      active_personal_access_tokens_detail = ::API::Entities::PersonalAccessTokenWithDetails
        .represent([active_personal_access_token])

      expect(assigns(:active_personal_access_tokens).to_json).to eq(active_personal_access_tokens_detail.to_json)
    end

    it "sets PAT name and scopes" do
      name = 'My PAT'
      scopes = 'api,read_user'

      get :index, params: { name: name, scopes: scopes }

      expect(assigns(:personal_access_token)).to have_attributes(
        name: eq(name),
        scopes: contain_exactly(:api, :read_user)
      )
    end
  end

  context 'access_token_ajax feature flag disabled' do
    before do
      stub_feature_flags(access_token_ajax: false)
      PersonalAccessToken.redis_store!(user.id, token_value)
      get :index
    end

    describe '#index' do
      let!(:active_personal_access_token) { create(:personal_access_token, user: user) }
      let!(:inactive_personal_access_token) { create(:personal_access_token, :revoked, user: user) }
      let!(:impersonation_personal_access_token) { create(:personal_access_token, :impersonation, user: user) }
      let(:token_value) { 's3cr3t' }

      it "retrieves active personal access tokens" do
        expect(assigns(:active_personal_access_tokens)).to include(active_personal_access_token)
      end

      it "does not retrieve impersonation tokens or inactive personal access tokens" do
        expect(assigns(:active_personal_access_tokens)).not_to include(impersonation_personal_access_token)
        expect(assigns(:active_personal_access_tokens)).not_to include(inactive_personal_access_token)
      end

      it "retrieves newly created personal access token value" do
        expect(assigns(:new_personal_access_token)).to eql(token_value)
      end

      it "sets PAT name and scopes" do
        name = 'My PAT'
        scopes = 'api,read_user'

        get :index, params: { name: name, scopes: scopes }

        expect(assigns(:personal_access_token)).to have_attributes(
          name: eq(name),
          scopes: contain_exactly(:api, :read_user)
        )
      end
    end
  end
end
