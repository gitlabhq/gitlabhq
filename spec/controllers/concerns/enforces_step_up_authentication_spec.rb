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

    it 'sets flash notice' do
      subject

      expect(flash[:notice]).to include 'Step-up authentication failed.'
    end

    context 'when feature flag :omniauth_step_up_auth_for_admin_mode is disabled' do
      before do
        stub_feature_flags(omniauth_step_up_auth_for_admin_mode: false)
      end

      it_behaves_like 'passing check for step up authentication'
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

    let(:provider_oidc_and_doc_link) do
      GitlabSettings::Options.new(
        name: 'oidc_and_doc_link',
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

    let(:session_oidc_succeeded) do
      { 'oidc' => { 'admin_mode' => { 'state' => 'succeeded' } } }
    end

    let(:session_oidc_failed) do
      { 'oidc' => { 'admin_mode' => { 'state' => 'failed' } } }
    end

    let(:session_oidc_and_doc_link_failed) do
      { 'oidc_and_doc_link' => { 'admin_mode' => { 'state' => 'failed' } } }
    end

    before do
      stub_omniauth_setting(enabled: true, providers: oauth_providers)
      allow(Devise).to receive(:omniauth_providers).and_return(oauth_providers.map(&:name))

      session.merge!(omniauth_step_up_auth: step_up_auth_session)
    end

    # rubocop:disable Layout/LineLength -- Avoid formatting table to keep oneline table syntax
    where(:oauth_providers, :step_up_auth_session, :expected_examples) do
      []                                                                                      | nil                                                                  | 'passing check for step up authentication'
      []                                                                                      | ref(:session_oidc_succeeded)                                         | 'passing check for step up authentication'
      []                                                                                      | ref(:session_oidc_failed)                                            | 'passing check for step up authentication'
      [ref(:provider_oidc_no_step_up)]                                                        | nil                                                                  | 'passing check for step up authentication'

      [ref(:provider_oidc), ref(:provider_oidc_no_step_up)]                                   | nil                                                                  | 'redirecting to new_admin_session_path'
      [ref(:provider_oidc), ref(:provider_oidc_and_doc_link), ref(:provider_oidc_no_step_up)] | ref(:session_oidc_and_doc_link_failed)                               | 'redirecting to new_admin_session_path with documentation link in notice'
      [ref(:provider_oidc), ref(:provider_oidc_and_doc_link)]                                 | lazy { session_oidc_failed.merge(session_oidc_and_doc_link_failed) } | 'redirecting to new_admin_session_path with documentation link in notice'
      [ref(:provider_oidc)]                                                                   | ref(:session_oidc_succeeded)                                         | 'passing check for step up authentication'
      [ref(:provider_oidc)]                                                                   | ref(:session_oidc_failed)                                            | 'redirecting to new_admin_session_path'
    end
    # rubocop:enable Layout/LineLength

    with_them do
      it_behaves_like params[:expected_examples]
    end
  end
end
