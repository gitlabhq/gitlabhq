# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::Users::TwoFactorGroupsFinder, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:group_not_requiring_2fa) { create :group, owners: user }

  describe '#execute' do
    subject(:execute) { described_class.new(user).execute }

    context 'when user is direct member of group requiring 2FA' do
      let_it_be(:group) { create :group, require_two_factor_authentication: true, owners: user }

      it 'returns the group' do
        is_expected.to contain_exactly(group)
      end
    end

    context 'when user is member of group which parent requires 2FA' do
      let_it_be(:parent_group) { create :group, require_two_factor_authentication: true }
      let_it_be(:group) { create :group, parent: parent_group, owners: user }

      it 'returns the parent group' do
        is_expected.to contain_exactly(parent_group)
      end
    end

    context 'when user is not a member of any group' do
      let_it_be(:user) { create(:user) }

      it { is_expected.to be_empty }
    end

    context 'with source_only: true' do
      subject(:execute) { described_class.new(user, source_only: true).execute }

      context 'when user is direct member of group requiring 2FA' do
        let_it_be(:group) { create :group, require_two_factor_authentication: true, owners: user }

        it 'returns the group' do
          is_expected.to contain_exactly(group)
        end
      end

      context 'when user is member of group which parent requires 2FA' do
        let_it_be(:parent_group) { create :group, require_two_factor_authentication: true }
        let_it_be(:group) { create :group, parent: parent_group, owners: user }

        it 'returns the membership group, not the enforcing parent' do
          is_expected.to contain_exactly(group)
        end
      end

      context 'when user is member of group which child requires 2FA' do
        let_it_be(:group) { create :group, owners: user }
        let_it_be(:child_group) { create :group, require_two_factor_authentication: true, parent: group }

        it 'returns the membership group' do
          is_expected.to contain_exactly(group)
        end
      end
    end
  end
end
