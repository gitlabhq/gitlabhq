# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EnforcesStepUpAuthentication, feature_category: :system_access do
  include AdminModeHelper

  controller(ApplicationController) do
    include EnforcesStepUpAuthentication

    def index
      head :ok
    end
  end

  let_it_be(:user) { create(:user) }

  subject do
    get :index
    response
  end

  before do
    sign_in(user)
  end

  shared_examples 'passing check for step up authentication' do
    it { is_expected.to have_gitlab_http_status(:ok) }
  end

  shared_examples 'redirecting to new_admin_session_path' do
    it { is_expected.to redirect_to(new_admin_session_path) }

    context 'when feature flag :omniauth_step_up_auth_for_admin_mode is disabled' do
      before do
        stub_feature_flags(omniauth_step_up_auth_for_admin_mode: false)
      end

      it_behaves_like 'passing check for step up authentication'
    end
  end

  describe '#enforce_step_up_authentication' do
    using RSpec::Parameterized::TableSyntax

    let(:provider_without_step_up_auth) { GitlabSettings::Options.new(name: 'google_oauth2') }
    let(:provider_with_step_up_auth) do
      GitlabSettings::Options.new(
        name: 'openid_connect',
        step_up_auth: {
          admin_mode: {
            id_token: {
              required: {
                acr: 'gold'
              }
            }
          }
        }
      )
    end

    let(:step_up_auth_session_succeeded) do
      { 'openid_connect' => { 'admin_mode' => { 'state' => 'succeeded' } } }
    end

    let(:step_up_auth_session_failed) { { 'openid_connect' => { 'admin_mode' => { 'state' => 'failed' } } } }

    before do
      stub_omniauth_setting(enabled: true, providers: oauth_providers)

      session.merge!(omniauth_step_up_auth: step_up_auth_session)
    end

    # rubocop:disable Layout/LineLength -- Avoid formatting table to keep oneline table syntax
    where(:oauth_providers, :step_up_auth_session, :expected_examples) do
      []                                                                      | nil                                  | 'passing check for step up authentication'
      []                                                                      | ref(:step_up_auth_session_succeeded) | 'passing check for step up authentication'
      []                                                                      | ref(:step_up_auth_session_failed)    | 'passing check for step up authentication'
      [ref(:provider_without_step_up_auth)]                                   | nil                                  | 'passing check for step up authentication'

      [ref(:provider_with_step_up_auth), ref(:provider_without_step_up_auth)] | nil                                  | 'redirecting to new_admin_session_path'
      [ref(:provider_with_step_up_auth)]                                      | ref(:step_up_auth_session_succeeded) | 'passing check for step up authentication'
      [ref(:provider_with_step_up_auth)]                                      | ref(:step_up_auth_session_failed)    | 'redirecting to new_admin_session_path'
    end
    # rubocop:enable Layout/LineLength

    with_them do
      it_behaves_like params[:expected_examples]
    end
  end
end
