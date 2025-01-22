# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Oauth::ApplicationsController, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:application) { create(:oauth_application, owner: user) }

  context 'project members' do
    before do
      sign_in(user)
    end

    shared_examples 'redirects to login page when the user is not signed in' do
      before do
        sign_out(user)
      end

      it { is_expected.to redirect_to(new_user_session_path) }
    end

    shared_examples 'redirects to 2fa setup page when the user requires it' do
      context 'when 2fa is set up on application level' do
        before do
          stub_application_setting(require_two_factor_authentication: true)
        end

        it { is_expected.to redirect_to(profile_two_factor_auth_path) }
      end

      context 'when 2fa is set up on group level' do
        let(:user) { create(:user, require_two_factor_authentication_from_group: true) }

        it { is_expected.to redirect_to(profile_two_factor_auth_path) }
      end
    end

    describe 'GET #new' do
      subject { get :new }

      it { is_expected.to have_gitlab_http_status(:ok) }

      it_behaves_like 'redirects to login page when the user is not signed in'
      it_behaves_like 'redirects to 2fa setup page when the user requires it'
    end

    describe 'DELETE #destroy' do
      subject { delete :destroy, params: { id: application.id } }

      it { is_expected.to redirect_to(oauth_applications_url) }

      it_behaves_like 'redirects to login page when the user is not signed in'
      it_behaves_like 'redirects to 2fa setup page when the user requires it'
    end

    describe 'GET #edit' do
      subject { get :edit, params: { id: application.id } }

      it { is_expected.to have_gitlab_http_status(:ok) }

      it_behaves_like 'redirects to login page when the user is not signed in'
      it_behaves_like 'redirects to 2fa setup page when the user requires it'
    end

    describe 'PUT #update' do
      subject { put :update, params: { id: application.id, doorkeeper_application: { name: 'application' } } }

      it { is_expected.to redirect_to(oauth_application_url(application)) }

      it_behaves_like 'redirects to login page when the user is not signed in'
      it_behaves_like 'redirects to 2fa setup page when the user requires it'
    end

    describe 'PUT #renew' do
      let(:oauth_params) do
        {
          id: application.id
        }
      end

      subject { put :renew, params: oauth_params }

      it { is_expected.to have_gitlab_http_status(:ok) }
      it { expect { subject }.to change { application.reload.secret } }

      it_behaves_like 'redirects to login page when the user is not signed in'
      it_behaves_like 'redirects to 2fa setup page when the user requires it'

      it 'returns the prefixed secret in json format' do
        subject

        expect(json_response['secret']).to match(/gloas-\h{64}/)
      end

      context 'when renew fails' do
        before do
          allow_next_found_instance_of(Doorkeeper::Application) do |application|
            allow(application).to receive(:save).and_return(false)
          end
        end

        it { expect { subject }.not_to change { application.reload.secret } }
        it { is_expected.to have_gitlab_http_status(:unprocessable_entity) }
      end
    end

    describe 'GET #show' do
      subject { get :show, params: { id: application.id } }

      it { is_expected.to have_gitlab_http_status(:ok) }

      it_behaves_like 'redirects to login page when the user is not signed in'
      it_behaves_like 'redirects to 2fa setup page when the user requires it'
    end

    describe 'GET #index' do
      subject(:get_index) { get :index }

      it { is_expected.to have_gitlab_http_status(:ok) }

      it 'sets the total count' do
        get_index

        expect(assigns(:applications_total_count)).to eq(1)
        expect(assigns(:applications).has_next_page?).to be_falsey
      end

      context 'when more than 20 applications' do
        before do
          create_list(:oauth_application, 20, owner: user) # rubocop:disable FactoryBot/ExcessiveCreateList -- paginator shows if > 20 applications
        end

        it 'has paginator' do
          get_index

          expect(assigns(:applications_total_count)).to eq(21)
          expect(assigns(:applications).has_next_page?).to be_truthy
        end
      end

      context 'when OAuth applications are disabled' do
        before do
          disable_user_oauth
        end

        it { is_expected.to have_gitlab_http_status(:ok) }
      end

      it_behaves_like 'redirects to login page when the user is not signed in'
      it_behaves_like 'redirects to 2fa setup page when the user requires it'
    end

    describe 'POST #create' do
      let(:oauth_params) do
        {
          doorkeeper_application: {
            name: 'foo',
            redirect_uri: redirect_uri,
            scopes: scopes
          }
        }
      end

      let(:redirect_uri) { 'http://example.org' }
      let(:scopes) { ['api'] }

      subject { post :create, params: oauth_params }

      it 'creates an application' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template :show
      end

      context 'the secret' do
        render_views

        it 'is in the response' do
          subject
          expect(response.body).to match(/gloas-\h{64}/)
        end
      end

      it 'redirects back to profile page if OAuth applications are disabled' do
        disable_user_oauth

        subject

        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(user_settings_profile_path)
      end

      context 'when redirect_uri is invalid' do
        let(:redirect_uri) { 'javascript://alert()' }

        render_views

        it 'shows an error for a forbidden URI' do
          subject

          expect(response.body).to include 'Redirect URI is forbidden by the server'
          expect(response).to render_template('doorkeeper/applications/index')
        end
      end

      context 'when scopes are not present' do
        let(:scopes) { [] }

        render_views

        it 'shows an error for blank scopes' do
          subject

          expect(response.body).to include 'Scopes can&#39;t be blank'
          expect(response).to render_template('doorkeeper/applications/index')
        end
      end

      context 'when scopes are invalid' do
        let(:scopes) { %w[api foo] }

        render_views

        it 'shows an error for invalid scopes' do
          subject

          expect(response.body).to include 'Scopes doesn&#39;t match configured on the server.'
          expect(response).to render_template('doorkeeper/applications/index')
        end
      end

      it_behaves_like 'redirects to login page when the user is not signed in'
      it_behaves_like 'redirects to 2fa setup page when the user requires it'
    end
  end

  context 'Helpers' do
    it 'current_user_mode available' do
      expect(subject.current_user_mode).not_to be_nil
    end

    it 'includes Two-factor enforcement concern' do
      expect(described_class.included_modules.include?(EnforcesTwoFactorAuthentication)).to eq(true)
    end
  end

  describe 'locale' do
    let(:user) { create(:user, preferred_language: 'uk') }

    before do
      sign_in(user)

      allow(Gitlab::I18n).to receive(:with_locale).and_call_original
    end

    it "sets user's locale" do
      expect(Gitlab::I18n).to receive(:with_locale).with('uk')

      get :new
    end
  end

  def disable_user_oauth
    allow(Gitlab::CurrentSettings.current_application_settings).to receive(:user_oauth_applications?).and_return(false)
  end
end
