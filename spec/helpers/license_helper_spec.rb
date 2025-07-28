# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LicenseHelper, feature_category: :team_planning do
  subject(:new_trial_url) { helper.self_managed_new_trial_url }

  before do
    allow(helper).to receive(:current_user).and_return(current_user)
  end

  context "when current_user does not exists" do
    let(:current_user) { nil }

    it "does not return the new trial url" do
      expect(new_trial_url).to be_nil
    end
  end

  context "when current_user exists" do
    let(:current_user) { build_stubbed(:user) }

    before do
      allow(helper).to receive(:subscription_portal_new_trial_url).with(
        return_to: CGI.escape(Gitlab.config.gitlab.url),
        id: Base64.strict_encode64(current_user.email)
      ).and_return('subscription_portal_trial_url')
    end

    it "returns the trial url" do
      expect(new_trial_url).to eq('subscription_portal_trial_url')
    end
  end
end
