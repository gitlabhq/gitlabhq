require 'spec_helper'

describe Admin::ApplicationSettingsController do
  include StubENV

  let(:admin) { create(:admin) }

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
  end

  describe 'PUT #update' do
    before do
      sign_in(admin)
    end

    it 'updates the EE specific application settings' do
      settings = {
          help_text: 'help_text',
          elasticsearch_url: 'http://my-elastic.search:9200',
          elasticsearch_indexing: true,
          elasticsearch_aws: true,
          elasticsearch_aws_access_key: 'elasticsearch_aws_access_key',
          elasticsearch_aws_secret_access_key: 'elasticsearch_aws_secret_access_key',
          elasticsearch_aws_region: 'elasticsearch_aws_region',
          elasticsearch_search: true,
          repository_size_limit: 1024,
          shared_runners_minutes: 60,
          geo_status_timeout: 30,
          elasticsearch_experimental_indexer: true,
          check_namespace_plan: true,
          authorized_keys_enabled: true,
          slack_app_enabled: true,
          slack_app_id: 'slack_app_id',
          slack_app_secret: 'slack_app_secret',
          slack_app_verification_token: 'slack_app_verification_token',
          allow_group_owners_to_manage_ldap: false
      }

      put :update, application_setting: settings

      expect(response).to redirect_to(admin_application_settings_path)
      settings.except(:elasticsearch_url, :repository_size_limit).each do |setting, value|
        expect(ApplicationSetting.current.public_send(setting)).to eq(value)
      end
      expect(ApplicationSetting.current.repository_size_limit).to eq(settings[:repository_size_limit].megabytes)
      expect(ApplicationSetting.current.elasticsearch_url).to contain_exactly(settings[:elasticsearch_url])
    end

    shared_examples 'settings for licensed features' do
      it 'does not update settings when licesed feature is not available' do
        stub_licensed_features(feature => false)
        attribute_names = settings.keys.map(&:to_s)

        expect { put :update, application_setting: settings }
          .not_to change { ApplicationSetting.current.reload.attributes.slice(*attribute_names) }
      end

      it 'updates settings when the feature is available' do
        stub_licensed_features(feature => true)

        put :update, application_setting: settings

        settings.each do |attribute, value|
          expect(ApplicationSetting.current.public_send(attribute)).to eq(value)
        end
      end
    end

    context 'mirror settings' do
      let(:settings) do
        {
          mirror_max_delay: (Gitlab::Mirror.min_delay_upper_bound / 60) + 1,
          mirror_max_capacity: 200,
          mirror_capacity_threshold: 2
        }
      end
      let(:feature) { :repository_mirrors }

      it_behaves_like 'settings for licensed features'
    end

    context 'external policy classification settings' do
      let(:settings) do
        {
          external_authorization_service_enabled: true,
          external_authorization_service_url: 'https://custom.service/',
          external_authorization_service_default_label: 'default',
          external_authorization_service_timeout: 3,
          external_auth_client_cert: File.read('ee/spec/fixtures/passphrase_x509_certificate.crt'),
          external_auth_client_key: File.read('ee/spec/fixtures/passphrase_x509_certificate_pk.key'),
          external_auth_client_key_pass: "5iveL!fe"
        }
      end
      let(:feature) { :external_authorization_service }

      it_behaves_like 'settings for licensed features'
    end

    it 'updates the default_project_creation for string value' do
      stub_licensed_features(project_creation_level: true)
      put :update, application_setting: { default_project_creation: ::EE::Gitlab::Access::MASTER_PROJECT_ACCESS }

      expect(response).to redirect_to(admin_application_settings_path)
      expect(ApplicationSetting.current.default_project_creation).to eq(::EE::Gitlab::Access::MASTER_PROJECT_ACCESS)
    end
  end
end
