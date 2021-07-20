# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApplicationSettingsHelper do
  context 'when all protocols in use' do
    before do
      stub_application_setting(enabled_git_access_protocol: '')
    end

    it { expect(all_protocols_enabled?).to be_truthy }
    it { expect(http_enabled?).to be_truthy }
    it { expect(ssh_enabled?).to be_truthy }
  end

  context 'when SSH is only in use' do
    before do
      stub_application_setting(enabled_git_access_protocol: 'ssh')
    end

    it { expect(all_protocols_enabled?).to be_falsey }
    it { expect(http_enabled?).to be_falsey }
    it { expect(ssh_enabled?).to be_truthy }
  end

  shared_examples 'when HTTP protocol is in use' do |protocol|
    before do
      allow(Gitlab.config.gitlab).to receive(:protocol).and_return(protocol)
      stub_application_setting(enabled_git_access_protocol: 'http')
    end

    it { expect(all_protocols_enabled?).to be_falsey }
    it { expect(http_enabled?).to be_truthy }
    it { expect(ssh_enabled?).to be_falsey }
  end

  it_behaves_like 'when HTTP protocol is in use', 'https'
  it_behaves_like 'when HTTP protocol is in use', 'http'

  describe '.visible_attributes' do
    it 'contains tracking parameters' do
      expect(helper.visible_attributes).to include(*%i(snowplow_collector_hostname snowplow_cookie_domain snowplow_enabled snowplow_app_id))
    end

    it 'contains :deactivate_dormant_users' do
      expect(helper.visible_attributes).to include(:deactivate_dormant_users)
    end

    context 'when GitLab.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it 'does not contain :deactivate_dormant_users' do
        expect(helper.visible_attributes).not_to include(:deactivate_dormant_users)
      end
    end
  end

  describe '.integration_expanded?' do
    let(:application_setting) { build(:application_setting) }

    it 'is expanded' do
      application_setting.plantuml_enabled = true
      application_setting.valid?
      helper.instance_variable_set(:@application_setting, application_setting)

      expect(helper.integration_expanded?('plantuml_')).to be_truthy
    end

    it 'is not expanded' do
      application_setting.valid?
      helper.instance_variable_set(:@application_setting, application_setting)

      expect(helper.integration_expanded?('plantuml_')).to be_falsey
    end
  end

  describe '.self_monitoring_project_data' do
    context 'when self monitoring project does not exist' do
      it 'returns create_self_monitoring_project_path' do
        expect(helper.self_monitoring_project_data).to include(
          'create_self_monitoring_project_path' =>
            create_self_monitoring_project_admin_application_settings_path
        )
      end

      it 'returns status_create_self_monitoring_project_path' do
        expect(helper.self_monitoring_project_data).to include(
          'status_create_self_monitoring_project_path' =>
            status_create_self_monitoring_project_admin_application_settings_path
        )
      end

      it 'returns delete_self_monitoring_project_path' do
        expect(helper.self_monitoring_project_data).to include(
          'delete_self_monitoring_project_path' =>
            delete_self_monitoring_project_admin_application_settings_path
        )
      end

      it 'returns status_delete_self_monitoring_project_path' do
        expect(helper.self_monitoring_project_data).to include(
          'status_delete_self_monitoring_project_path' =>
            status_delete_self_monitoring_project_admin_application_settings_path
        )
      end

      it 'returns self_monitoring_project_exists false' do
        expect(helper.self_monitoring_project_data).to include(
          'self_monitoring_project_exists' => "false"
        )
      end

      it 'returns nil for project full_path' do
        expect(helper.self_monitoring_project_data).to include(
          'self_monitoring_project_full_path' => nil
        )
      end
    end

    context 'when self monitoring project exists' do
      let(:project) { build(:project) }

      before do
        stub_application_setting(self_monitoring_project: project)
      end

      it 'returns self_monitoring_project_exists true' do
        expect(helper.self_monitoring_project_data).to include(
          'self_monitoring_project_exists' => "true"
        )
      end

      it 'returns project full_path' do
        expect(helper.self_monitoring_project_data).to include(
          'self_monitoring_project_full_path' => project.full_path
        )
      end
    end
  end

  describe '.storage_weights' do
    let(:application_setting) { build(:application_setting) }

    before do
      helper.instance_variable_set(:@application_setting, application_setting)
      stub_storage_settings({ 'default': {}, 'storage_1': {}, 'storage_2': {} })
      stub_application_setting(repository_storages_weighted: { 'default' => 100, 'storage_1' => 50, 'storage_2' => nil })
    end

    it 'returns storages correctly' do
      expect(helper.storage_weights).to eq(OpenStruct.new(
                                             default: 100,
                                             storage_1: 50,
                                             storage_2: 0
                                           ))
    end
  end

  describe '.show_documentation_base_url_field?' do
    subject { helper.show_documentation_base_url_field? }

    before do
      stub_feature_flags(help_page_documentation_redirect: feature_flag)
    end

    context 'when feature flag is enabled' do
      let(:feature_flag) { true }

      it { is_expected.to eq(true) }
    end

    context 'when feature flag is disabled' do
      let(:feature_flag) { false }

      it { is_expected.to eq(false) }
    end
  end

  describe '.valid_runner_registrars' do
    subject { helper.valid_runner_registrars }

    context 'when only admins are permitted to register runners' do
      before do
        stub_application_setting(valid_runner_registrars: [])
      end

      it { is_expected.to eq [] }
    end

    context 'when group and project users are permitted to register runners' do
      before do
        stub_application_setting(valid_runner_registrars: ApplicationSetting::VALID_RUNNER_REGISTRAR_TYPES)
      end

      it { is_expected.to eq ApplicationSetting::VALID_RUNNER_REGISTRAR_TYPES }
    end
  end

  describe '.signup_enabled?' do
    subject { helper.signup_enabled? }

    context 'when signup is enabled' do
      before do
        stub_application_setting(signup_enabled: true)
      end

      it { is_expected.to be true }
    end

    context 'when signup is disabled' do
      before do
        stub_application_setting(signup_enabled: false)
      end

      it { is_expected.to be false }
    end

    context 'when `signup_enabled` is nil' do
      before do
        stub_application_setting(signup_enabled: nil)
      end

      it { is_expected.to be false }
    end
  end

  describe '.kroki_available_formats' do
    let(:application_setting) { build(:application_setting) }

    before do
      helper.instance_variable_set(:@application_setting, application_setting)
      stub_application_setting(kroki_formats: { 'blockdiag' => true, 'bpmn' => false, 'excalidraw' => false })
    end

    it 'returns available formats correctly' do
      expect(helper.kroki_available_formats).to eq([
                                             {
                                               name: 'kroki_formats_blockdiag',
                                               label: 'BlockDiag (includes BlockDiag, SeqDiag, ActDiag, NwDiag, PacketDiag, and RackDiag)',
                                               value: true
                                             },
                                             {
                                               name: 'kroki_formats_bpmn',
                                               label: 'BPMN',
                                               value: false
                                             },
                                             {
                                               name: 'kroki_formats_excalidraw',
                                               label: 'Excalidraw',
                                               value: false
                                             }
                                           ])
    end
  end
end
