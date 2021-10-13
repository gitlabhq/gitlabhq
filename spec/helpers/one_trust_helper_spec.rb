# frozen_string_literal: true

require "spec_helper"

RSpec.describe OneTrustHelper do
  describe '#one_trust_enabled?' do
    let(:user) { nil }

    before do
      stub_config(extra: { one_trust_id: SecureRandom.uuid })
      allow(helper).to receive(:current_user).and_return(user)
    end

    subject(:one_trust_enabled?) { helper.one_trust_enabled? }

    context 'with ecomm_instrumentation feature flag disabled' do
      before do
        stub_feature_flags(ecomm_instrumentation: false)
      end

      context 'when id is set and no user is set' do
        let(:user) { instance_double('User') }

        it { is_expected.to be_falsey }
      end
    end

    context 'with ecomm_instrumentation feature flag enabled' do
      context 'when current user is set' do
        let(:user) { instance_double('User') }

        it { is_expected.to be_falsey }
      end

      context 'when no id is set' do
        before do
          stub_config(extra: {})
        end

        it { is_expected.to be_falsey }
      end

      context 'when id is set and no user is set' do
        it { is_expected.to be_truthy }
      end
    end
  end
end
