# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::GroupsFinder, feature_category: :cell do
  include AdminModeHelper

  let(:current_user) { user }
  let(:params) { {} }
  let(:finder) { described_class.new(organization: organization, current_user: current_user, params: params) }

  let_it_be(:organization_user) { create(:organization_user) }
  let_it_be(:organization) { organization_user.organization }
  let_it_be(:user) { organization_user.user }
  let_it_be(:public_group) { create(:group, name: 'public-group', organization: organization) }
  let_it_be(:other_group) { create(:group, name: 'other-group', organization: organization) }
  let_it_be(:outside_organization_group) { create(:group) }
  let_it_be(:private_group) do
    create(:group, :private, name: 'private-group', organization: organization)
  end

  let_it_be(:no_access_group_in_org) do
    create(:group, :private, name: 'no-access', organization: organization)
  end

  before_all do
    private_group.add_developer(user)
    public_group.add_developer(user)
    other_group.add_developer(user)
    outside_organization_group.add_developer(user)
  end

  subject(:result) { finder.execute.to_a }

  describe '#execute' do
    context 'when user is not authorized to read the organization' do
      let(:current_user) { create(:user) }

      it { is_expected.to be_empty }
    end

    context 'when organization is nil' do
      let(:finder) { described_class.new(organization: nil, current_user: current_user, params: params) }

      it { is_expected.to be_empty }
    end

    context 'when user is authorized to read the organization' do
      it 'return all accessible groups' do
        expect(result).to contain_exactly(public_group, private_group, other_group)
      end

      context 'when search param is passed' do
        let(:params) { { search: 'the' } }

        it 'filters the groups by search' do
          expect(result).to contain_exactly(other_group)
        end
      end

      context 'when sort param is not passed' do
        it 'return groups sorted by name in ascending order by default' do
          expect(result).to eq([other_group, private_group, public_group])
        end
      end

      context 'when sort param is passed' do
        using RSpec::Parameterized::TableSyntax

        where(:field, :direction, :sorted_groups) do
          'name' | 'asc'  | lazy { [other_group, private_group, public_group] }
          'name' | 'desc' | lazy { [public_group, private_group, other_group] }
          'path' | 'asc'  | lazy { [other_group, private_group, public_group] }
          'path' | 'desc' | lazy { [public_group, private_group, other_group] }
        end

        with_them do
          let(:params) { { sort: { field: field, direction: direction } } }
          it 'sorts the groups' do
            expect(result).to eq(sorted_groups)
          end
        end
      end
    end
  end
end
