# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::ApplicationSettingsController, :do_not_mock_admin_mode_setting do
  include StubENV
  include UsageDataHelpers

  let(:group) { create(:group) }
  let(:project) { create(:project, namespace: group) }
  let(:admin) { create(:admin) }
  let(:user) { create(:user)}

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
  end

  describe 'GET #integrations' do
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

  describe 'GET #usage_data with no access' do
    before do
      stub_usage_data_connections
      sign_in(user)
    end

    it 'returns 404' do
      get :usage_data, format: :html

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'GET #usage_data' do
    before do
      stub_usage_data_connections
      sign_in(admin)
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
  end

  describe 'PUT #update' do
    before do
      sign_in(admin)
    end

    it 'updates the require_admin_approval_after_user_signup setting' do
      put :update, params: { application_setting: { require_admin_approval_after_user_signup: true } }

      expect(response).to redirect_to(general_admin_application_settings_path)
      expect(ApplicationSetting.current.require_admin_approval_after_user_signup).to eq(true)
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

    it "updates admin_mode setting" do
      put :update, params: { application_setting: { admin_mode: true } }

      expect(response).to redirect_to(general_admin_application_settings_path)
      expect(ApplicationSetting.current.admin_mode).to be(true)
    end

    it 'updates valid_runner_registrars setting' do
      put :update, params: { application_setting: { valid_runner_registrars: ['project', ''] } }

      expect(response).to redirect_to(general_admin_application_settings_path)
      expect(ApplicationSetting.current.valid_runner_registrars).to eq(['project'])
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
  end

  describe 'PUT #reset_registration_token' do
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
end
