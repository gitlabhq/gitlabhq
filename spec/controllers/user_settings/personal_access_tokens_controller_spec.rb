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

    it_behaves_like "create access token" do
      let(:url) { :create }
    end
  end

  describe '#toggle_dpop' do
    context "when feature flag is enabled" do
      before do
        stub_feature_flags(dpop_authentication: true)
      end

      context "when toggling dpop" do
        it "enables dpop" do
          put :toggle_dpop, params: { user: { dpop_enabled: "1" } }
          expect(access_token_user.dpop_enabled).to be(true)
        end

        it "disables dpop" do
          put :toggle_dpop, params: { user: { dpop_enabled: "0" } }
          expect(access_token_user.dpop_enabled).to be(false)
        end
      end

      context 'when user preference update succeeds' do
        it 'shows a success flash message' do
          put :toggle_dpop, params: { user: { dpop_enabled: "1" } }
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
          put :toggle_dpop, params: { user: { dpop_enabled: "1" } }
          expect(flash[:warning]).to eq(_('Unable to update DPoP preference.'))
        end
      end
    end

    context "when feature flag is disabled" do
      before do
        stub_feature_flags(dpop_authentication: false)
      end

      it "redirects to controller" do
        put :toggle_dpop, params: { user: { dpop_enabled: "1" } }

        expect(response).to redirect_to(user_settings_personal_access_tokens_path)
        expect(access_token_user.dpop_enabled).to be(false)
      end
    end
  end

  describe '#index' do
    it "builds a PAT with name, description and scopes from params" do
      name = 'My PAT'
      scopes = 'api,read_user,invalid'
      description = 'My PAT description'

      get :index, params: { name: name, scopes: scopes, description: description }

      expect(assigns(:access_token_params)).to include(
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

  describe '#new' do
    context 'when fine_grained_personal_access_tokens feature flag is disabled' do
      before do
        stub_feature_flags(fine_grained_personal_access_tokens: false)
      end

      it 'returns 404' do
        get :new

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when feature flag is enabled' do
      before do
        stub_feature_flags(fine_grained_personal_access_tokens: true)
      end

      it 'renders the new template' do
        get :new

        expect(response).to render_template(:new)
      end
    end
  end
end
