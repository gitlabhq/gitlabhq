# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserSettings::PersonalAccessTokensController, feature_category: :system_access do
  let(:access_token_user) { create(:user) }
  let(:token_attributes) { attributes_for(:personal_access_token) }

  before do
    sign_in(access_token_user)
  end

  describe '#create' do
    let(:token_params) { token_attributes }

    subject(:create_token) { post :create, params: { personal_access_token: token_params } }

    def created_token
      PersonalAccessToken.order(:created_at).last
    end

    context 'with scopes' do
      let(:name) { 'My PAT' }
      let(:scopes) { %w[api read_user] }
      let(:token_params) { token_attributes.merge(scopes: scopes, name: name) }

      it "allows creation of a token with scopes" do
        create_token

        expect(created_token).not_to be_nil
        expect(created_token.name).to eq(name)
        expect(created_token.scopes).to eq(scopes)
        expect(PersonalAccessToken.active).to include(created_token)
      end
    end

    context 'with workflow scope' do
      let(:token_params) { token_attributes.merge(scopes: %w[ai_workflow], name: 'My PAT') }

      it "does not allow creation of a token with workflow scope" do
        create_token

        expect(created_token).to be_nil
        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end

    context 'with dynamic user scope' do
      let(:token_params) { token_attributes.merge(scopes: %w[user:*], name: 'My PAT') }

      it "does not allow creation of a token with a dynamic user scope" do
        create_token

        expect(created_token).to be_nil
        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end

    context 'with expiry date' do
      let(:expires_at) { 5.days.from_now.to_date }
      let(:token_params) { token_attributes.merge(expires_at: expires_at) }

      it "allows creation of a token with an expiry date" do
        create_token

        expect(created_token).not_to be_nil
        expect(created_token.expires_at).to eq(expires_at)
      end
    end

    context 'when personal access tokens are disabled' do
      before do
        allow(::Gitlab::CurrentSettings).to receive_messages(personal_access_tokens_disabled?: true)
      end

      it 'does not allow creation' do
        create_token

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    it_behaves_like "create access token" do
      let(:url) { :create }
    end
  end

  describe '#toggle_dpop' do
    let(:dpop_enabled) { "1" }

    subject(:toggle_dpop) { put :toggle_dpop, params: { user: { dpop_enabled: dpop_enabled } } }

    context "when `dpop_authentication` feature flag is enabled" do
      before do
        stub_feature_flags(dpop_authentication: true)
      end

      context "when toggling dpop" do
        it "enables dpop" do
          toggle_dpop

          expect(access_token_user.dpop_enabled).to be(true)
        end

        context 'when disabling' do
          let(:dpop_enabled) { "0" }

          it "disables dpop" do
            toggle_dpop

            expect(access_token_user.dpop_enabled).to be(false)
          end
        end
      end

      context 'when user preference update succeeds' do
        it 'shows a success flash message' do
          toggle_dpop

          expect(flash[:notice]).to eq(_('DPoP preference updated.'))
        end
      end

      context 'when user preference update fails' do
        before do
          allow_next_instance_of(UserPreferences::UpdateService) do |instance|
            allow(instance).to receive(:execute)
                                 .and_return(ServiceResponse.error(message: 'Could not update preference'))
          end
        end

        it 'shows a failure flash message' do
          toggle_dpop

          expect(flash[:warning]).to eq(_('Unable to update DPoP preference.'))
        end
      end
    end

    context "when `dpop_authentication` feature flag is disabled" do
      before do
        stub_feature_flags(dpop_authentication: false)
      end

      it "redirects to controller" do
        toggle_dpop

        expect(response).to redirect_to(user_settings_personal_access_tokens_path)
        expect(access_token_user.dpop_enabled).to be(false)
      end
    end
  end

  describe '#index' do
    let(:params) { {} }

    subject(:get_index) { get :index, params: params }

    context 'when `granular_personal_access_tokens` feature flag is enabled' do
      before do
        stub_feature_flags(granular_personal_access_tokens: true)
      end

      context 'when VSCode extension parameters are present' do
        let(:params) do
          {
            name: 'GitLab Workflow Extension',
            scopes: 'api,read_user',
            description: 'Token for VSCode'
          }
        end

        it 'redirects to legacy_new with VSCode extension params' do
          get_index

          expect(response).to redirect_to(action: :legacy_new, **params)
        end
      end

      context 'when VSCode extension parameters are present but in a different case' do
        let(:params) do
          {
            name: 'gitLab workflow extension',
            scopes: 'api,read_user',
            description: 'Token for VSCode'
          }
        end

        it 'redirects to legacy_new with VSCode extension params' do
          get_index

          expect(response).to redirect_to(action: :legacy_new, **params)
        end
      end

      context 'when name is not `GitLab Workflow Extension`' do
        let(:params) { { name: 'Other Token', scopes: 'api' } }

        it 'does not redirect' do
          get_index

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).not_to be_redirect
        end
      end

      context 'when no name parameter is provided' do
        it 'does not redirect' do
          get_index

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).not_to be_redirect
        end
      end
    end

    context 'when `granular_personal_access_tokens` feature flag is disabled' do
      before do
        stub_feature_flags(granular_personal_access_tokens: false)
      end

      let(:params) { { name: 'GitLab Workflow Extension', scopes: 'api' } }

      it 'does not redirect' do
        get_index

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).not_to be_redirect
      end
    end

    context 'with query parameters' do
      let(:name) { 'My PAT' }
      let(:scopes) { 'api,read_user,invalid' }
      let(:description) { 'My PAT description' }
      let(:params) { { name: name, scopes: scopes, description: description } }

      it 'sets access_token_params from query parameters' do
        get_index

        expect(assigns(:access_token_params)).to include(
          name: eq(name),
          description: eq(description),
          scopes: contain_exactly(:api, :read_user)
        )
      end
    end

    context 'when personal access tokens are disabled' do
      before do
        allow(::Gitlab::CurrentSettings).to receive_messages(personal_access_tokens_disabled?: true)
      end

      it 'returns 404' do
        get_index

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    it 'returns an iCalendar after redirect for ics format' do
      token = create(:personal_access_token, user: access_token_user)
      expires_at = token.expires_at.strftime('%Y%m%d')

      get :index, params: { format: :ics }

      expect(response).to redirect_to(%r{/-/user_settings/personal_access_tokens.ics\?feed_token=})

      get :index, params: { format: :ics, feed_token: response.location.split('=').last }

      expect(response.body).to include('BEGIN:VCALENDAR')
      expect(response.body).to include("DTSTART;VALUE=DATE:#{expires_at}")
      expect(response.body).to include("DTEND;VALUE=DATE:#{expires_at}")
      expect(response.body).to include("SUMMARY:#{format(_("Token '%{name}' expires today"), name: token.name)}")
    end
  end

  describe '#granular_new' do
    subject(:get_granular_new) { get :granular_new }

    context 'when `granular_personal_access_tokens` feature flag is disabled' do
      before do
        stub_feature_flags(granular_personal_access_tokens: false)
      end

      it 'returns 404' do
        get_granular_new

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when `granular_personal_access_tokens` feature flag is enabled' do
      before do
        stub_feature_flags(granular_personal_access_tokens: true)
      end

      it 'renders the granular_new template' do
        get_granular_new

        expect(response).to render_template(:granular_new)
      end
    end
  end

  describe '#legacy_new' do
    let(:params) { {} }

    subject(:get_legacy_new) { get :legacy_new, params: params }

    context 'when `granular_personal_access_tokens` feature flag is disabled' do
      before do
        stub_feature_flags(granular_personal_access_tokens: false)
      end

      it 'returns 404' do
        get_legacy_new

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when `granular_personal_access_tokens` feature flag is enabled' do
      before do
        stub_feature_flags(granular_personal_access_tokens: true)
      end

      it 'renders the legacy_new template' do
        get_legacy_new

        expect(response).to render_template(:legacy_new)
      end

      context 'with query parameters' do
        let(:name) { 'GitLab Workflow Extension' }
        let(:scopes) { 'api,read_user,invalid' }
        let(:description) { 'VSCode token' }
        let(:params) { { name: name, scopes: scopes, description: description } }

        it 'sets access_token_params from query parameters' do
          get_legacy_new

          expect(assigns(:access_token_params)).to include(
            name: eq(name),
            description: eq(description),
            scopes: contain_exactly(:api, :read_user)
          )
        end
      end
    end
  end
end
