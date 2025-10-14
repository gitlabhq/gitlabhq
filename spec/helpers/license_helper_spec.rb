# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LicenseHelper, feature_category: :team_planning do
  subject(:new_trial_url) { helper.self_managed_new_trial_url }

  before do
    allow(helper).to receive(:subscription_portal_new_trial_url).with(
      return_to: CGI.escape(Gitlab.config.gitlab.url)
    ).and_return('subscription_portal_trial_url')
  end

  it { is_expected.to eq('subscription_portal_trial_url') }
end
