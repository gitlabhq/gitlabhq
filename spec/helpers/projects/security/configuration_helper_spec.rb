# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Security::ConfigurationHelper do
  let(:current_user) { create(:user) }

  describe 'security_upgrade_path' do
    subject { security_upgrade_path }

    it { is_expected.to eq('https://about.gitlab.com/pricing/') }
  end
end
