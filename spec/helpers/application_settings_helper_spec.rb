# frozen_string_literal: true

require 'spec_helper'

describe ApplicationSettingsHelper do
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

  context 'with tracking parameters' do
    it { expect(visible_attributes).to include(*%i(snowplow_collector_hostname snowplow_cookie_domain snowplow_enabled snowplow_app_id)) }
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

      it 'returns self_monitoring_project_exists false' do
        expect(helper.self_monitoring_project_data).to include(
          'self_monitoring_project_exists' => false
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
        stub_application_setting(instance_administration_project: project)
      end

      it 'returns self_monitoring_project_exists true' do
        expect(helper.self_monitoring_project_data).to include(
          'self_monitoring_project_exists' => true
        )
      end

      it 'returns project full_path' do
        expect(helper.self_monitoring_project_data).to include(
          'self_monitoring_project_full_path' => project.full_path
        )
      end
    end
  end
end
