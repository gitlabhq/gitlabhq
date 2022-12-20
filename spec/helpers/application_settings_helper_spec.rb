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

    it 'contains :deactivate_dormant_users_period' do
      expect(helper.visible_attributes).to include(:deactivate_dormant_users_period)
    end

    it 'contains rate limit parameters' do
      expect(helper.visible_attributes).to include(
        *%i(
          issues_create_limit notes_create_limit project_export_limit
          project_download_export_limit project_export_limit project_import_limit
          raw_blob_request_limit group_export_limit group_download_export_limit
          group_import_limit users_get_by_id_limit search_rate_limit search_rate_limit_unauthenticated
        ))
    end

    context 'when GitLab.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it 'does not contain :deactivate_dormant_users' do
        expect(helper.visible_attributes).not_to include(:deactivate_dormant_users)
      end

      it 'does not contain :deactivate_dormant_users_period' do
        expect(helper.visible_attributes).not_to include(:deactivate_dormant_users_period)
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
    context 'when self-monitoring project does not exist' do
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

    context 'when self-monitoring project exists' do
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

  describe '#storage_weights' do
    let(:application_setting) { build(:application_setting) }

    before do
      helper.instance_variable_set(:@application_setting, application_setting)
      stub_storage_settings({ 'default': {}, 'storage_1': {}, 'storage_2': {} })
      stub_application_setting(repository_storages_weighted: { 'default' => 100, 'storage_1' => 50, 'storage_2' => nil })
    end

    it 'returns storage objects with assigned weights' do
      expect(helper.storage_weights)
        .to have_attributes(
          default: 100,
          storage_1: 50,
          storage_2: 0
        )
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
      expect(helper.kroki_available_formats).to eq(
        [
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

  describe '.pending_user_count' do
    let(:user_cap) { 200 }

    before do
      stub_application_setting(new_user_signups_cap: user_cap)
    end

    subject(:pending_user_count) { helper.pending_user_count }

    context 'when new_user_signups_cap is present' do
      it 'returns the number of blocked pending users' do
        create(:user, state: :blocked_pending_approval)

        expect(pending_user_count).to eq 1
      end
    end
  end

  describe '.registration_features_can_be_prompted?', :without_license do
    subject { helper.registration_features_can_be_prompted? }

    context 'when service ping is enabled' do
      before do
        stub_application_setting(usage_ping_enabled: true)
      end

      it { is_expected.to be_falsey }
    end

    context 'when service ping is disabled' do
      before do
        stub_application_setting(usage_ping_enabled: false)
      end

      it { is_expected.to be_truthy }
    end
  end

  describe '.spam_check_endpoint_enabled?' do
    subject { helper.spam_check_endpoint_enabled? }

    context 'when spam check endpoint is enabled' do
      before do
        stub_application_setting(spam_check_endpoint_enabled: true)
      end

      it { is_expected.to be true }
    end

    context 'when spam check endpoint is disabled' do
      before do
        stub_application_setting(spam_check_endpoint_enabled: false)
      end

      it { is_expected.to be false }
    end
  end

  describe '.anti_spam_service_enabled?' do
    subject { helper.anti_spam_service_enabled? }

    context 'when akismet is enabled and spam check endpoint is disabled' do
      before do
        stub_application_setting(spam_check_endpoint_enabled: false)
        stub_application_setting(akismet_enabled: true)
      end

      it { is_expected.to be true }
    end

    context 'when akismet is disabled and spam check endpoint is enabled' do
      before do
        stub_application_setting(spam_check_endpoint_enabled: true)
        stub_application_setting(akismet_enabled: false)
      end

      it { is_expected.to be true }
    end

    context 'when akismet and spam check endpoint are both enabled' do
      before do
        stub_application_setting(spam_check_endpoint_enabled: true)
        stub_application_setting(akismet_enabled: true)
      end

      it { is_expected.to be true }
    end

    context 'when akismet and spam check endpoint are both disabled' do
      before do
        stub_application_setting(spam_check_endpoint_enabled: false)
        stub_application_setting(akismet_enabled: false)
      end

      it { is_expected.to be false }
    end
  end

  describe '#sidekiq_job_limiter_modes_for_select' do
    subject { helper.sidekiq_job_limiter_modes_for_select }

    it { is_expected.to eq([%w(Track track), %w(Compress compress)]) }
  end

  describe '#instance_clusters_enabled?', :request_store do
    let_it_be(:user) { create(:user) }

    subject { helper.instance_clusters_enabled? }

    before do
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:can?).with(user, :read_cluster, instance_of(Clusters::Instance)).and_return(true)
    end

    it { is_expected.to be_truthy }

    context ':certificate_based_clusters feature flag is disabled' do
      before do
        stub_feature_flags(certificate_based_clusters: false)
      end

      it { is_expected.to be_falsey }
    end
  end
end
