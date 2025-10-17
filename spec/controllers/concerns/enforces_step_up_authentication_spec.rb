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

  let_it_be(:user) { create(:admin) }

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

    it 'disables admin mode' do
      current_user_mode = instance_double(Gitlab::Auth::CurrentUserMode, admin_mode?: true, disable_admin_mode!: true)
      allow(controller).to receive(:current_user_mode).and_return(current_user_mode)
      expect(current_user_mode).to receive(:disable_admin_mode!)

      subject
    end

    context 'when feature flag :omniauth_step_up_auth_for_admin_mode is disabled' do
      before do
        stub_feature_flags(omniauth_step_up_auth_for_admin_mode: false)
      end

      it_behaves_like 'passing check for step up authentication'
    end
  end

  shared_examples 'redirecting to new_admin_session_path with notice failure' do
    it_behaves_like 'redirecting to new_admin_session_path'

    it 'sets the flash notice for expired step-up auth session' do
      subject

      expect(flash[:notice]).to eq('Step-up authentication failed.')
    end
  end

  shared_examples 'redirecting to new_admin_session_path with documentation link in notice' do
    it_behaves_like 'redirecting to new_admin_session_path'

    it 'includes documenetation link in flash notice' do
      subject

      expect(flash[:notice]).to include 'Step-up authentication failed. Learn more about authentication requirements:'
      expect(flash[:notice]).to include example_doc_link
    end
  end

  shared_examples 'redirecting to new_admin_session_path with notice expiration' do
    it_behaves_like 'redirecting to new_admin_session_path'

    it 'sets the flash notice for expired step-up auth session' do
      subject

      expect(flash[:notice]).to eq('Step-up authentication session has expired. Please authenticate again.')
    end
  end

  describe '#enforce_step_up_authentication' do
    using RSpec::Parameterized::TableSyntax

    let(:example_doc_link) { 'https://example.com/company-internal-docs-for-step-up-auth' }

    let(:provider_oidc_no_step_up) { GitlabSettings::Options.new(name: 'oidc_no_step_up') }
    let(:provider_oidc) do
      GitlabSettings::Options.new(
        name: 'oidc',
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

    let(:provider_oidc_doc_link) do
      GitlabSettings::Options.new(
        name: 'oidc_doc_link',
        step_up_auth: {
          admin_mode: {
            documentation_link: example_doc_link,
            id_token: {
              required: {
                acr: 'gold'
              }
            }
          }
        }
      )
    end

    let(:session_unknown_succeeded) { { 'unknown' => { 'admin_mode' => { 'state' => 'succeeded' } } } }
    let(:session_oidc_succeeded) { { 'oidc' => { 'admin_mode' => { 'state' => 'succeeded' } } } }

    let(:session_oidc_succeeded_and_not_expired) do
      {
        'oidc' => {
          'admin_mode' => {
            'state' => 'succeeded',
            'exp_timestamp' => 1.minute.from_now.to_i
          }
        }
      }
    end

    let(:session_oidc_succeeded_and_expired) do
      {
        'oidc' => {
          'admin_mode' => {
            'state' => 'succeeded',
            'exp_timestamp' => 1.minute.ago.to_i
          }
        }
      }
    end

    let(:session_oidc_failed) { { 'oidc' => { 'admin_mode' => { 'state' => 'failed' } } } }

    let(:session_oidc_doc_link_failed) { { 'oidc_doc_link' => { 'admin_mode' => { 'state' => 'failed' } } } }

    let(:session_oidc_expired) do
      {
        'oidc' => {
          'admin_mode' => {
            'state' => 'expired',
            'exp_timestamp' => 1.minute.ago.to_i
          }
        }
      }
    end

    let(:session_oidc_doc_link_expired) do
      {
        'oidc_doc_link' => {
          'admin_mode' => {
            'state' => 'expired',
            'exp_timestamp' => 1.minute.ago.to_i
          }
        }
      }
    end

    let(:multi_session_oidc_succeeded) do
      {
        **session_oidc_succeeded,
        **session_oidc_doc_link_expired
      }
    end

    let(:multi_session_oidc_succeeded_and_not_expired) do
      {
        **session_oidc_succeeded_and_not_expired,
        **session_oidc_doc_link_expired
      }
    end

    let(:multi_session_oidc_succeeded_and_expired) do
      {
        **session_oidc_succeeded_and_expired,
        **session_oidc_doc_link_expired
      }
    end

    let(:multi_session_with_doc_link_failed) do
      {
        **session_oidc_failed,
        **session_oidc_doc_link_failed
      }
    end

    before do
      stub_omniauth_setting(enabled: true, providers: oauth_providers)
      allow(Devise).to receive(:omniauth_providers).and_return(oauth_providers.map(&:name))

      session.merge!(omniauth_step_up_auth: step_up_auth_session)
    end

    # rubocop:disable Layout/LineLength -- Avoid formatting table to keep oneline table syntax
    where(:oauth_providers, :step_up_auth_session, :expected_examples) do
      []                                                                                  | nil                                                | 'passing check for step up authentication'
      []                                                                                  | ref(:session_oidc_succeeded)                       | 'passing check for step up authentication'
      []                                                                                  | ref(:session_oidc_failed)                          | 'passing check for step up authentication'
      [ref(:provider_oidc_no_step_up)]                                                    | nil                                                | 'passing check for step up authentication'

      [ref(:provider_oidc), ref(:provider_oidc_no_step_up)]                               | nil                                                | 'redirecting to new_admin_session_path'
      [ref(:provider_oidc), ref(:provider_oidc_doc_link), ref(:provider_oidc_no_step_up)] | ref(:session_oidc_doc_link_failed)                 | 'redirecting to new_admin_session_path with documentation link in notice'
      [ref(:provider_oidc), ref(:provider_oidc_doc_link)]                                 | ref(:multi_session_with_doc_link_failed)           | 'redirecting to new_admin_session_path with documentation link in notice'
      [ref(:provider_oidc)]                                                               | ref(:session_oidc_succeeded)                       | 'passing check for step up authentication'
      [ref(:provider_oidc)]                                                               | ref(:session_oidc_failed)                          | 'redirecting to new_admin_session_path'
      [ref(:provider_oidc), ref(:provider_oidc_no_step_up)]                               | nil                                                | 'redirecting to new_admin_session_path with notice failure'
      [ref(:provider_oidc)]                                                               | ref(:session_oidc_succeeded_and_not_expired)       | 'passing check for step up authentication'
      [ref(:provider_oidc)]                                                               | ref(:session_oidc_succeeded_and_expired)           | 'redirecting to new_admin_session_path with notice expiration'
      [ref(:provider_oidc)]                                                               | ref(:session_oidc_expired)                         | 'redirecting to new_admin_session_path with notice expiration'

      # The following test case occurs e.g. when the session includes a provider that used to have step-up authentication configured.
      [ref(:provider_oidc)]                                                               | ref(:session_unknown_succeeded)                    | 'redirecting to new_admin_session_path with notice failure'

      # The following test cases check for multiple providers in the session
      [ref(:provider_oidc), ref(:provider_oidc_doc_link)]                                 | ref(:multi_session_oidc_succeeded)                 | 'passing check for step up authentication'
      [ref(:provider_oidc), ref(:provider_oidc_doc_link)]                                 | ref(:multi_session_oidc_succeeded_and_not_expired) | 'passing check for step up authentication'
      [ref(:provider_oidc), ref(:provider_oidc_doc_link)]                                 | ref(:multi_session_oidc_succeeded_and_expired)     | 'redirecting to new_admin_session_path with notice expiration'
    end
    # rubocop:enable Layout/LineLength

    with_them do
      it_behaves_like params[:expected_examples]
    end
  end
end
