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
end
