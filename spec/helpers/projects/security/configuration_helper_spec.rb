# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Security::ConfigurationHelper, feature_category: :security_testing_configuration do
  let(:current_user) { build_stubbed(:user) }

  describe 'security_upgrade_path' do
    subject { security_upgrade_path }

    it { is_expected.to eq(promo_pricing_url) }
  end

  describe 'vulnerability_training_docs_path' do
    subject { helper.vulnerability_training_docs_path }

    it { is_expected.to eq(help_page_path('user/application_security/vulnerabilities/_index.md', anchor: 'enable-security-training-for-vulnerabilities')) }
  end
end
