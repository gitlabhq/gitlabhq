# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EnforcesStepUpAuthenticationForNamespace, feature_category: :system_access do
  controller(Groups::ApplicationController) do
    # InternalRedirect is required by EnforcesStepUpAuthenticationForNamespace
    include InternalRedirect
    include EnforcesStepUpAuthenticationForNamespace

    before_action :enforce_step_up_auth_for_namespace

    def index
      head :ok
    end

    private

    def enforce_step_up_auth_for_namespace
      enforce_step_up_auth_for(group) if group
    end
  end

  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user, owner_of: group) }

  subject do
    get :index, params: { group_id: group.to_param }
    response
  end

  before do
    sign_in(user)
  end

  shared_examples 'passing check for namespace step up authentication' do
    it { is_expected.to have_gitlab_http_status(:ok) }
  end

  shared_examples 'redirecting to new_group_step_up_auth_path' do
    it { is_expected.to redirect_to(new_group_step_up_auth_path(group)) }

    context 'when feature flag :omniauth_step_up_auth_for_namespace is disabled' do
      before do
        stub_feature_flags(omniauth_step_up_auth_for_namespace: false)
      end

      it_behaves_like 'passing check for namespace step up authentication'
    end
  end

  shared_examples 'redirecting to new_group_step_up_auth_path with documentation link in notice' do
    it_behaves_like 'redirecting to new_group_step_up_auth_path'
  end

  describe '#enforce_step_up_auth_for' do
    using RSpec::Parameterized::TableSyntax

    let(:example_doc_link) { 'https://example.com/company-internal-docs-for-step-up-auth' }

    let(:provider_oidc_no_step_up) { GitlabSettings::Options.new(name: 'oidc_no_step_up') }
    let(:provider_oidc) do
      GitlabSettings::Options.new(
        name: 'oidc',
        step_up_auth: {
          namespace: {
            id_token: {
              required: {
                acr: 'silver'
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
          namespace: {
            documentation_link: example_doc_link,
            id_token: {
              required: {
                acr: 'silver'
              }
            }
          }
        }
      )
    end

    let(:session_oidc_succeeded) do
      { 'oidc' => { 'namespace' => { 'state' => 'succeeded' } } }
    end

    let(:session_oidc_failed) do
      { 'oidc' => { 'namespace' => { 'state' => 'failed' } } }
    end

    let(:session_oidc_and_doc_link_failed) do
      { 'oidc_and_doc_link' => { 'namespace' => { 'state' => 'failed' } } }
    end

    before do
      stub_omniauth_setting(enabled: true, providers: oauth_providers)
      allow(Devise).to receive(:omniauth_providers).and_return(oauth_providers.map(&:name))

      session[:omniauth_step_up_auth] = step_up_auth_session

      # Only set the provider if it's valid (has step-up auth configured)
      if required_provider &&
          ::Gitlab::Auth::Oidc::StepUpAuthentication
            .enabled_providers(scope: :namespace)
            .include?(required_provider)
        group.update!(step_up_auth_required_oauth_provider: required_provider)
      end
    end

    # rubocop:disable Layout/LineLength -- Avoid formatting table to keep oneline table syntax
    where(:oauth_providers, :required_provider, :step_up_auth_session, :expected_examples) do
      []                                                                                      | nil                        | nil                                                                  | 'passing check for namespace step up authentication'
      []                                                                                      | nil                        | ref(:session_oidc_succeeded)                                         | 'passing check for namespace step up authentication'
      []                                                                                      | nil                        | ref(:session_oidc_failed)                                            | 'passing check for namespace step up authentication'
      [ref(:provider_oidc_no_step_up)]                                                        | nil                        | nil                                                                  | 'passing check for namespace step up authentication'

      [ref(:provider_oidc), ref(:provider_oidc_no_step_up)]                                   | 'oidc'                     | nil                                                                  | 'redirecting to new_group_step_up_auth_path'
      [ref(:provider_oidc), ref(:provider_oidc_and_doc_link), ref(:provider_oidc_no_step_up)] | 'oidc_and_doc_link'        | ref(:session_oidc_and_doc_link_failed)                               | 'redirecting to new_group_step_up_auth_path with documentation link in notice'
      [ref(:provider_oidc)]                                                                   | 'oidc'                     | ref(:session_oidc_succeeded)                                         | 'passing check for namespace step up authentication'
    end
    # rubocop:enable Layout/LineLength

    with_them do
      it_behaves_like params[:expected_examples]
    end

    context 'when group does not require step-up auth' do
      let(:oauth_providers) { [provider_oidc] }
      let(:required_provider) { nil }
      let(:step_up_auth_session) { nil }

      it_behaves_like 'passing check for namespace step up authentication'
    end

    context 'when group is not defined' do
      let(:oauth_providers) { [provider_oidc] }
      let(:required_provider) { 'oidc' }
      let(:step_up_auth_session) { nil }

      before do
        allow(controller).to receive(:group).and_return(nil)
      end

      it_behaves_like 'passing check for namespace step up authentication'
    end
  end
end
