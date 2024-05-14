# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::GroupsFinder, feature_category: :groups_and_projects do
  describe '#execute' do
    let_it_be(:organization_user) { create(:organization_user) }
    let_it_be(:organization) { organization_user.organization }
    let_it_be(:user) { organization_user.user }
    let_it_be(:public_group) { create(:group, name: 'public-group', organization: organization) }
    let_it_be(:outside_organization_group) { create(:group) }
    let_it_be(:private_group) { create(:group, :private, name: 'private-group', organization: organization) }
    let_it_be(:no_access_group_in_org) { create(:group, :private, name: 'no-access', organization: organization) }

    let(:current_user) { user }
    let(:params) { { organization: organization } }
    let(:finder) { described_class.new(current_user, params) }

    subject(:result) { finder.execute.to_a }

    before_all do
      private_group.add_developer(user)
      public_group.add_developer(user)
      outside_organization_group.add_developer(user)
    end

    context 'when user is only authorized to read the public group' do
      let(:current_user) { create(:user) }

      it { is_expected.to contain_exactly(public_group) }
    end

    it 'return all groups inside the organization' do
      expect(result).to contain_exactly(public_group, private_group)
    end

    it 'creates a CTE with filtered groups' do
      allow(Gitlab::SQL::CTE).to receive(:new).and_call_original
      expect(Gitlab::SQL::CTE).to receive(:new).with(
        :filtered_groups_cte, kind_of(ActiveRecord::Relation), materialized: false
      )

      result
    end

    context 'with default organization' do
      before do
        allow(organization).to receive(:default?).and_return(true)
      end

      it { is_expected.to contain_exactly(public_group, private_group) }

      it 'does not build a query using the CTE' do
        allow(Gitlab::SQL::CTE).to receive(:new).and_call_original
        expect(Gitlab::SQL::CTE).not_to receive(:new).with(
          :filtered_groups_cte, kind_of(ActiveRecord::Relation), materialized: false
        )

        result
      end
    end
  end
end
