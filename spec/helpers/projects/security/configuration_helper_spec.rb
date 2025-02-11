# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Security::ConfigurationHelper do
  let(:current_user) { create(:user) }

  describe 'security_upgrade_path' do
    subject { security_upgrade_path }

    it { is_expected.to eq("#{ApplicationHelper.promo_url}/pricing/") }
  end

  describe 'vulnerability_training_docs_path' do
    subject { helper.vulnerability_training_docs_path }

    it { is_expected.to eq(help_page_path('user/application_security/vulnerabilities/_index.md', anchor: 'enable-security-training-for-vulnerabilities')) }
  end
end
