# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::CrmSettingsHelper do
  let_it_be(:group) { create(:group) }

  describe '#crm_feature_flag_enabled?' do
    subject do
      helper.crm_feature_flag_enabled?(group)
    end

    context 'when feature flag is enabled' do
      it { is_expected.to be_truthy }
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(customer_relations: false)
      end

      it { is_expected.to be_falsy }
    end
  end
end
