# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::CrmSettingsHelper do
  let_it_be(:root_group) { create(:group) }

  describe '#crm_feature_available?' do
    subject do
      helper.crm_feature_available?(group)
    end

    context 'in root group' do
      let(:group) { root_group }

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

    context 'in subgroup' do
      let_it_be(:subgroup) { create(:group, parent: root_group) }

      let(:group) { subgroup }

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
end
