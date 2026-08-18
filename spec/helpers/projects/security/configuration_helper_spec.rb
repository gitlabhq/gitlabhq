# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Security::ConfigurationHelper, feature_category: :security_testing_configuration do
  describe 'vulnerability_training_docs_path' do
    subject { helper.vulnerability_training_docs_path }

    it { is_expected.to eq(help_page_path('user/application_security/vulnerabilities/_index.md', anchor: 'enable-security-training-for-vulnerabilities')) }
  end
end
