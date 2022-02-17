# frozen_string_literal: true

require "spec_helper"

RSpec.describe BizibleHelper do
  describe '#bizible_enabled?' do
    before do
      stub_config(extra: { bizible: SecureRandom.uuid })
    end

    context 'when bizible is disabled' do
      before do
        allow(helper).to receive(:bizible_enabled?).and_return(false)
      end

      it { is_expected.to be_falsey }
    end

    context 'when bizible is enabled' do
      before do
        allow(helper).to receive(:bizible_enabled?).and_return(true)
      end

      it { is_expected.to be_truthy }
    end

    subject(:bizible_enabled?) { helper.bizible_enabled? }

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
