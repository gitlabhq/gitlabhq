require 'spec_helper'

describe Admin::ApplicationSettingsController do # rubocop:disable RSpec/FilePath
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
          slack_app_verification_token: 'slack_app_verification_token'
      }

      put :update, application_setting: settings

      expect(response).to redirect_to(admin_application_settings_path)
      settings.except(:elasticsearch_url, :repository_size_limit).each do |setting, value|
        expect(ApplicationSetting.current.public_send(setting)).to eq(value)
      end
      expect(ApplicationSetting.current.repository_size_limit).to eq(settings[:repository_size_limit].megabytes)
      expect(ApplicationSetting.current.elasticsearch_url).to contain_exactly(settings[:elasticsearch_url])
    end

    it 'does not update mirror settings when repository mirrors unlicensed' do
      stub_licensed_features(repository_mirrors: false)

      settings = {
        mirror_max_delay: 12,
        mirror_max_capacity: 2,
        mirror_capacity_threshold: 2
      }

      settings.each do |setting, _value|
        expect do
          put :update, application_setting: settings
        end.not_to change(ApplicationSetting.current.reload, setting)
      end
    end

    it 'updates mirror settings when repository mirrors is licensed' do
      stub_licensed_features(repository_mirrors: true)

      mirror_delay = (Gitlab::Mirror.min_delay_upper_bound / 60) + 1

      settings = {
        mirror_max_delay: mirror_delay,
        mirror_max_capacity: 2,
        mirror_capacity_threshold: 2
      }

      put :update, application_setting: settings

      settings.each do |setting, value|
        expect(ApplicationSetting.current.public_send(setting)).to eq(value)
      end
    end
  end
end
