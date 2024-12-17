# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserSettings::PersonalAccessTokensController, feature_category: :system_access do
  let(:access_token_user) { create(:user) }
  let(:token_attributes) { attributes_for(:personal_access_token) }

  before do
    sign_in(access_token_user)
  end

  describe '#create', :with_current_organization do
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

    it "does not allow creation of a token with workflow scope" do
      name = 'My PAT'
      scopes = %w[ai_workflow]

      post :create, params: { personal_access_token: token_attributes.merge(scopes: scopes, name: name) }

      expect(created_token).to be_nil
      expect(response).to have_gitlab_http_status(:unprocessable_entity)
    end

    it "does not allow creation of a token with a dynamic user scope" do
      name = 'My PAT'
      scopes = %w[user:*]

      post :create, params: { personal_access_token: token_attributes.merge(scopes: scopes, name: name) }

      expect(created_token).to be_nil
      expect(response).to have_gitlab_http_status(:unprocessable_entity)
    end

    it "allows creation of a token with an expiry date" do
      expires_at = 5.days.from_now.to_date

      post :create, params: { personal_access_token: token_attributes.merge(expires_at: expires_at) }

      expect(created_token).not_to be_nil
      expect(created_token.expires_at).to eq(expires_at)
    end

    it 'does not allow creation when personal access tokens are disabled' do
      allow(::Gitlab::CurrentSettings).to receive_messages(personal_access_tokens_disabled?: true)

      post :create, params: { personal_access_token: token_attributes }

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it_behaves_like "#create access token" do
      let(:url) { :create }
    end
  end

  describe 'GET /-/user_settings/personal_access_tokens' do
    let(:get_access_tokens) do
      get :index
      response
    end

    subject(:get_access_tokens_with_page) do
      get :index, params: { page: 1 }
      response
    end

    it_behaves_like 'GET access tokens are paginated and ordered'
  end

  describe '#index' do
    let!(:active_personal_access_token) { create(:personal_access_token, user: access_token_user) }

    before do
      # Impersonation and inactive personal tokens are ignored
      create(:personal_access_token, :impersonation, user: access_token_user)
      create(:personal_access_token, :revoked, user: access_token_user)
      get :index
    end

    it "only includes details of active personal access tokens" do
      active_personal_access_tokens_detail =
        ::PersonalAccessTokenSerializer.new.represent([active_personal_access_token])

      expect(assigns(:active_access_tokens).to_json).to eq(active_personal_access_tokens_detail.to_json)
    end

    it "builds a PAT with name, description and scopes from params" do
      name = 'My PAT'
      scopes = 'api,read_user'
      description = 'My PAT description'

      get :index, params: { name: name, scopes: scopes, description: description }

      expect(assigns(:personal_access_token)).to have_attributes(
        name: eq(name),
        description: eq(description),
        scopes: contain_exactly(:api, :read_user)
      )
    end

    it 'returns 404 when personal access tokens are disabled' do
      allow(::Gitlab::CurrentSettings).to receive_messages(personal_access_tokens_disabled?: true)

      get :index

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns tokens for json format' do
      get :index, params: { format: :json }

      expect(json_response.count).to eq(1)
    end

    it 'returns an iCalendar after redirect for ics format' do
      get :index, params: { format: :ics }

      expect(response).to redirect_to(%r{/-/user_settings/personal_access_tokens\?feed_token=})

      get :index, params: { format: :ics, feed_token: response.location.split('=').last }

      expect(response.body).to include('BEGIN:VCALENDAR')
    end

    it 'sets available scopes' do
      expect(assigns(:scopes)).to eq(Gitlab::Auth.available_scopes_for(access_token_user))
    end
  end
end
