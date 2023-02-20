# frozen_string_literal: true

require "spec_helper"

RSpec.describe BizibleHelper do
  describe '#bizible_enabled?' do
    context 'when bizible config is not true' do
      before do
        stub_config(extra: { bizible: false })
      end

      it { expect(helper.bizible_enabled?).to be_falsy }
    end

    context 'when bizible config is enabled' do
      before do
        stub_config(extra: { bizible: true })
      end

      it { expect(helper.bizible_enabled?).to be_truthy }

      context 'with ecomm_instrumentation feature flag disabled' do
        before do
          stub_feature_flags(ecomm_instrumentation: false)
        end

        it { expect(helper.bizible_enabled?).to be_falsey }
      end

      context 'with ecomm_instrumentation feature flag enabled' do
        before do
          stub_feature_flags(ecomm_instrumentation: true)
        end

        it { expect(helper.bizible_enabled?).to be_truthy }
      end

      context 'with invite_email present' do
        before do
          stub_feature_flags(ecomm_instrumentation: true)
        end

        it { expect(helper.bizible_enabled?('test@test.com')).to be_falsy }
      end
    end
  end
end
