# frozen_string_literal: true

require 'spec_helper'

describe OnboardingExperimentHelper, type: :helper do
  describe '.allow_access_to_onboarding?' do
    context "when we're not gitlab.com" do
      it 'returns false' do
        allow(::Gitlab).to receive(:com?).and_return(false)

        expect(helper.allow_access_to_onboarding?).to be(false)
      end
    end

    context "when we're gitlab.com" do
      before do
        allow(::Gitlab).to receive(:com?).and_return(true)
      end

      context 'and the :user_onboarding feature is not enabled' do
        it 'returns false' do
          stub_feature_flags(user_onboarding: false)

          expect(helper.allow_access_to_onboarding?).to be(false)
        end
      end

      context 'and the :user_onboarding feature is enabled' do
        it 'returns true' do
          stub_feature_flags(user_onboarding: true)
          allow(helper).to receive(:current_user).and_return(create(:user))

          expect(helper.allow_access_to_onboarding?).to be(true)
        end
      end
    end
  end
end
