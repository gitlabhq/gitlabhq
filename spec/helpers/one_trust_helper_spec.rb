# frozen_string_literal: true

require "spec_helper"

RSpec.describe OneTrustHelper do
  describe '#one_trust_enabled?' do
    before do
      stub_config(extra: { one_trust_id: SecureRandom.uuid })
    end

    subject(:one_trust_enabled?) { helper.one_trust_enabled? }

    context 'with ecomm_instrumentation feature flag disabled' do
      before do
        stub_feature_flags(ecomm_instrumentation: false)
      end

      it { is_expected.to be_falsey }
    end

    context 'with ecomm_instrumentation feature flag enabled' do
      context 'when no id is set' do
        before do
          stub_config(extra: {})
        end

        it { is_expected.to be_falsey }
      end
    end
  end
end
