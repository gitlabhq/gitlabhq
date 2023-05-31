# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::ApplicationSettingsController, :do_not_mock_admin_mode_setting, feature_category: :shared do
  include StubENV
  include UsageDataHelpers

  let(:group) { create(:group) }
  let(:project) { create(:project, namespace: group) }
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
  end

  describe 'GET #integrations', feature_category: :integrations do
    before do
      sign_in(admin)
    end

    context 'when GitLab.com' do
      before do
        allow(::Gitlab).to receive(:com?) { true }
      end

      it 'returns 404' do
        get :integrations

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when not GitLab.com' do
      before do
        allow(::Gitlab).to receive(:com?) { false }
      end

      it 'renders correct template' do
        get :integrations

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template('admin/application_settings/integrations')
      end
    end
  end

  describe 'GET #usage_data with no access', feature_category: :service_ping do
    before do
      stub_usage_data_connections
      sign_in(user)
    end

    it 'returns 404' do
      get :usage_data, format: :html

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'GET #usage_data', feature_category: :service_ping do
    before do
      stub_usage_data_connections
      stub_database_flavor_check
      sign_in(admin)
    end

    context 'when there are recent ServicePing reports' do
      it 'attempts to use prerecorded data' do
        create(:raw_usage_data)

        expect(Gitlab::Usage::ServicePingReport).not_to receive(:for)

        get :usage_data, format: :json
      end
    end

    context 'when there are NO recent ServicePing reports' do
      it 'calculates data on the fly' do
        allow(Gitlab::Usage::ServicePingReport).to receive(:for).and_call_original

        get :usage_data, format: :json

        expect(Gitlab::Usage::ServicePingReport).to have_received(:for)
      end
    end

    it 'returns HTML data' do
      get :usage_data, format: :html

      expect(response.body).to start_with('<span')
      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'returns JSON data' do
      get :usage_data, format: :json

      body = json_response
      expect(body["version"]).to eq(Gitlab::VERSION)
      expect(body).to include('counts')
      expect(response).to have_gitlab_http_status(:ok)
    end

    describe 'usage data counter' do
      let(:counter) { Gitlab::UsageDataCounters::ServiceUsageDataCounter }

      it 'incremented when json generated' do
        expect { get :usage_data, format: :json }.to change { counter.read(:download_payload_click) }.by(1)
      end

      it 'not incremented when html format requested' do
        expect { get :usage_data }.not_to change { counter.read(:download_payload_click) }
      end
    end
  end

  describe 'PUT #update' do
    before do
      sign_in(admin)
    end

    it 'updates the password_authentication_enabled_for_git setting' do
      put :update, params: { application_setting: { password_authentication_enabled_for_git: "0" } }

      expect(response).to redirect_to(general_admin_application_settings_path)
      expect(ApplicationSetting.current.password_authentication_enabled_for_git).to eq(false)
    end

    it 'updates the default_project_visibility for string value' do
      put :update, params: { application_setting: { default_project_visibility: "20" } }

      expect(response).to redirect_to(general_admin_application_settings_path)
      expect(ApplicationSetting.current.default_project_visibility).to eq(Gitlab::VisibilityLevel::PUBLIC)
    end

    it 'update the restricted levels for string values' do
      put :update, params: { application_setting: { restricted_visibility_levels: %w[10 20] } }

      expect(response).to redirect_to(general_admin_application_settings_path)
      expect(ApplicationSetting.current.restricted_visibility_levels).to eq([10, 20])
    end

    it 'updates the restricted_visibility_levels when empty array is passed' do
      put :update, params: { application_setting: { restricted_visibility_levels: [""] } }

      expect(response).to redirect_to(general_admin_application_settings_path)
      expect(ApplicationSetting.current.restricted_visibility_levels).to be_empty
    end

    it 'updates the receive_max_input_size setting' do
      put :update, params: { application_setting: { receive_max_input_size: "1024" } }

      expect(response).to redirect_to(general_admin_application_settings_path)
      expect(ApplicationSetting.current.receive_max_input_size).to eq(1024)
    end

    it 'updates the default_preferred_language for string value' do
      put :update, params: { application_setting: { default_preferred_language: 'zh_CN' } }

      expect(response).to redirect_to(general_admin_application_settings_path)
      expect(ApplicationSetting.current.default_preferred_language).to eq('zh_CN')
    end

    it 'updates the default_project_creation for string value' do
      put :update, params: { application_setting: { default_project_creation: ::Gitlab::Access::MAINTAINER_PROJECT_ACCESS } }

      expect(response).to redirect_to(general_admin_application_settings_path)
      expect(ApplicationSetting.current.default_project_creation).to eq(::Gitlab::Access::MAINTAINER_PROJECT_ACCESS)
    end

    it 'updates minimum_password_length setting' do
      put :update, params: { application_setting: { minimum_password_length: 10 } }

      expect(response).to redirect_to(general_admin_application_settings_path)
      expect(ApplicationSetting.current.minimum_password_length).to eq(10)
    end

    it 'updates repository_storages_weighted setting' do
      put :update, params: { application_setting: { repository_storages_weighted: { default: 75 } } }

      expect(response).to redirect_to(general_admin_application_settings_path)
      expect(ApplicationSetting.current.repository_storages_weighted).to eq('default' => 75)
    end

    it 'updates kroki_formats setting' do
      put :update, params: { application_setting: { kroki_formats_excalidraw: '1' } }

      expect(response).to redirect_to(general_admin_application_settings_path)
      expect(ApplicationSetting.current.kroki_formats_excalidraw).to eq(true)
    end

    it "updates default_branch_name setting" do
      put :update, params: { application_setting: { default_branch_name: "example_branch_name" } }

      expect(response).to redirect_to(general_admin_application_settings_path)
      expect(ApplicationSetting.current.default_branch_name).to eq("example_branch_name")
    end

    it 'updates valid_runner_registrars setting' do
      put :update, params: { application_setting: { valid_runner_registrars: ['project', ''] } }

      expect(response).to redirect_to(general_admin_application_settings_path)
      expect(ApplicationSetting.current.valid_runner_registrars).to eq(['project'])
    end

    it 'updates GitLab for Slack app settings' do
      settings = {
        slack_app_enabled: true,
        slack_app_id: 'slack_app_id',
        slack_app_secret: 'slack_app_secret',
        slack_app_signing_secret: 'slack_app_signing_secret',
        slack_app_verification_token: 'slack_app_verification_token'
      }

      put :update, params: { application_setting: settings }

      expect(response).to redirect_to(general_admin_application_settings_path)
      expect(ApplicationSetting.current).to have_attributes(
        slack_app_enabled: true,
        slack_app_id: 'slack_app_id',
        slack_app_secret: 'slack_app_secret',
        slack_app_signing_secret: 'slack_app_signing_secret',
        slack_app_verification_token: 'slack_app_verification_token'
      )
    end

    context 'boolean attributes' do
      shared_examples_for 'updates boolean attribute' do |attribute|
        specify do
          existing_value = ApplicationSetting.current.public_send(attribute)
          new_value = !existing_value

          put :update, params: { application_setting: { attribute => new_value } }

          expect(response).to redirect_to(general_admin_application_settings_path)
          expect(ApplicationSetting.current.public_send(attribute)).to eq(new_value)
        end
      end

      it_behaves_like 'updates boolean attribute', :user_defaults_to_private_profile
      it_behaves_like 'updates boolean attribute', :can_create_group
      it_behaves_like 'updates boolean attribute', :admin_mode
      it_behaves_like 'updates boolean attribute', :require_admin_approval_after_user_signup
      it_behaves_like 'updates boolean attribute', :remember_me_enabled
    end

    context "personal access token prefix settings" do
      let(:application_settings) { ApplicationSetting.current }

      shared_examples "accepts prefix setting" do |prefix|
        it "updates personal_access_token_prefix setting" do
          put :update, params: { application_setting: { personal_access_token_prefix: prefix } }

          expect(response).to redirect_to(general_admin_application_settings_path)
          expect(application_settings.reload.personal_access_token_prefix).to eq(prefix)
        end
      end

      shared_examples "rejects prefix setting" do |prefix|
        it "does not update personal_access_token_prefix setting" do
          put :update, params: { application_setting: { personal_access_token_prefix: prefix } }

          expect(response).not_to redirect_to(general_admin_application_settings_path)
          expect(application_settings.reload.personal_access_token_prefix).not_to eq(prefix)
        end
      end

      context "with valid prefix" do
        include_examples("accepts prefix setting", "a_prefix@")
      end

      context "with blank prefix" do
        include_examples("accepts prefix setting", "")
      end

      context "with too long prefix" do
        include_examples("rejects prefix setting", "a_prefix@" * 10)
      end

      context "with invalid characters prefix" do
        include_examples("rejects prefix setting", "a_préfixñ:")
      end
    end

    context 'external policy classification settings' do
      let(:settings) do
        {
          external_authorization_service_enabled: true,
          external_authorization_service_url: 'https://custom.service/',
          external_authorization_service_default_label: 'default',
          external_authorization_service_timeout: 3,
          external_auth_client_cert: File.read('spec/fixtures/passphrase_x509_certificate.crt'),
          external_auth_client_key: File.read('spec/fixtures/passphrase_x509_certificate_pk.key'),
          external_auth_client_key_pass: "5iveL!fe"
        }
      end

      it 'updates settings when the feature is available' do
        put :update, params: { application_setting: settings }

        settings.each do |attribute, value|
          expect(ApplicationSetting.current.public_send(attribute)).to eq(value)
        end
      end
    end

    describe 'verify panel actions' do
      Admin::ApplicationSettingsController::VALID_SETTING_PANELS.each do |valid_action|
        it_behaves_like 'renders correct panels' do
          let(:action) { valid_action }
        end
      end
    end

    describe 'EKS integration' do
      let(:application_setting) { ApplicationSetting.current }
      let(:settings_params) do
        {
          eks_integration_enabled: '1',
          eks_account_id: '123456789012',
          eks_access_key_id: 'dummy access key',
          eks_secret_access_key: 'dummy secret key'
        }
      end

      it 'updates EKS settings' do
        put :update, params: { application_setting: settings_params }

        expect(application_setting.eks_integration_enabled).to be_truthy
        expect(application_setting.eks_account_id).to eq '123456789012'
        expect(application_setting.eks_access_key_id).to eq 'dummy access key'
        expect(application_setting.eks_secret_access_key).to eq 'dummy secret key'
      end

      context 'secret access key is blank' do
        let(:settings_params) { { eks_secret_access_key: '' } }

        it 'does not update the secret key' do
          application_setting.update!(eks_secret_access_key: 'dummy secret key')

          put :update, params: { application_setting: settings_params }

          expect(application_setting.reload.eks_secret_access_key).to eq 'dummy secret key'
        end
      end
    end

    describe 'Terraform settings' do
      let(:application_setting) { ApplicationSetting.current }

      context 'max_terraform_state_size_bytes' do
        it 'updates the receive_max_input_size setting' do
          put :update, params: { application_setting: { max_terraform_state_size_bytes: '123' } }

          expect(response).to redirect_to(general_admin_application_settings_path)
          expect(application_setting.max_terraform_state_size_bytes).to eq(123)
        end
      end
    end

    describe 'user_email_lookup_limit aliasing' do
      let(:application_setting) { ApplicationSetting.current }
      let(:user_email_lookup_limit) { 8675 }
      let(:search_rate_limit) { 309 }

      context 'when search_rate_limit is specified' do
        let(:settings_params) do
          {
            user_email_lookup_limit: user_email_lookup_limit,
            search_rate_limit: search_rate_limit
          }
        end

        it 'updates search_rate_limit with correct value' do
          expect(application_setting.search_rate_limit).not_to eq user_email_lookup_limit
          expect(application_setting.search_rate_limit).not_to eq search_rate_limit

          put :update, params: { application_setting: settings_params }

          expect(application_setting.reload.search_rate_limit).to eq search_rate_limit
        end
      end

      context 'when search_rate_limit is not specified' do
        let(:settings_params) do
          {
            user_email_lookup_limit: search_rate_limit
          }
        end

        it 'applies user_email_lookup_limit value to search_rate_limit' do
          expect(application_setting.search_rate_limit).not_to eq search_rate_limit

          put :update, params: { application_setting: settings_params }

          expect(application_setting.reload.search_rate_limit).to eq search_rate_limit
        end
      end
    end

    context 'pipeline creation rate limiting' do
      let(:application_settings) { ApplicationSetting.current }

      it 'updates pipeline_limit_per_project_user_sha setting' do
        put :update, params: { application_setting: { pipeline_limit_per_project_user_sha: 25 } }

        expect(response).to redirect_to(general_admin_application_settings_path)
        expect(application_settings.reload.pipeline_limit_per_project_user_sha).to eq(25)
      end
    end

    context 'invitation flow enforcement setting' do
      let(:application_settings) { ApplicationSetting.current }

      it 'updates invitation_flow_enforcement setting' do
        put :update, params: { application_setting: { invitation_flow_enforcement: true } }

        expect(response).to redirect_to(general_admin_application_settings_path)
        expect(application_settings.reload.invitation_flow_enforcement).to eq(true)
      end
    end

    context 'maximum includes' do
      let(:application_settings) { ApplicationSetting.current }

      it 'updates ci_max_includes setting' do
        put :update, params: { application_setting: { ci_max_includes: 200 } }

        expect(response).to redirect_to(general_admin_application_settings_path)
        expect(application_settings.reload.ci_max_includes).to eq(200)
      end
    end
  end

  describe 'PUT #reset_registration_token', feature_category: :user_management do
    before do
      sign_in(admin)
    end

    subject { put :reset_registration_token }

    it 'resets runner registration token' do
      expect { subject }.to change { ApplicationSetting.current.runners_registration_token }
    end

    it 'redirects the user to admin runners page' do
      subject

      expect(response).to redirect_to(admin_runners_path)
    end
  end

  describe 'PUT #reset_error_tracking_access_token', feature_category: :error_tracking do
    before do
      sign_in(admin)
    end

    subject { put :reset_error_tracking_access_token }

    it 'resets error_tracking_access_token' do
      expect { subject }.to change { ApplicationSetting.current.error_tracking_access_token }
    end

    it 'redirects the user to application settings page' do
      subject

      expect(response).to redirect_to(general_admin_application_settings_path)
    end
  end

  describe 'GET #lets_encrypt_terms_of_service' do
    include LetsEncryptHelpers

    before do
      sign_in(admin)

      stub_lets_encrypt_client
    end

    subject { get :lets_encrypt_terms_of_service }

    it 'redirects the user to the terms of service page' do
      subject

      expect(response).to redirect_to("https://letsencrypt.org/documents/LE-SA-v1.2-November-15-2017.pdf")
    end
  end

  describe 'GET #service_usage_data', feature_category: :service_ping do
    before do
      stub_usage_data_connections
      stub_database_flavor_check
      sign_in(admin)
    end

    it 'assigns truthy value if there are recent ServicePing reports in database' do
      create(:raw_usage_data)

      get :service_usage_data, format: :html

      expect(assigns(:service_ping_data_present)).to be_truthy
      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'assigns truthy value if there are recent ServicePing reports in cache', :use_clean_rails_memory_store_caching do
      Rails.cache.write('usage_data', true)

      get :service_usage_data, format: :html

      expect(assigns(:service_ping_data_present)).to be_truthy
      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'assigns falsey value if there are NO recent ServicePing reports' do
      get :service_usage_data, format: :html

      expect(assigns(:service_ping_data_present)).to be_falsey
      expect(response).to have_gitlab_http_status(:ok)
    end
  end
end
