# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::GroupsResolver, feature_category: :groups_and_projects do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:user) { create(:user) }
    let_it_be(:public_group) { create(:group, name: 'public-group') }
    let_it_be(:private_group) { create(:group, :private, name: 'private-group') }

    let(:params) { {} }

    subject { resolve(described_class, args: params, ctx: { current_user: user }) }

    it 'includes public groups' do
      expect(subject).to contain_exactly(public_group)
    end

    it 'includes accessible private groups' do
      private_group.add_developer(user)
      expect(subject).to contain_exactly(public_group, private_group)
    end

    describe 'ordering' do
      let_it_be(:other_group) { create(:group, name: 'other-group') }

      it 'orders by name ascending' do
        expect(subject.map(&:name)).to eq(%w[other-group public-group])
      end
    end

    context 'with `search` argument' do
      let_it_be(:other_group) { create(:group, name: 'other-group') }

      let(:params) { { search: 'oth' } }

      it 'filters groups by name' do
        expect(subject).to contain_exactly(other_group)
      end
    end

    context 'with `ids` argument' do
      let_it_be(:other_group) { create(:group, name: 'other-group') }

      let(:params) { { ids: [other_group.to_global_id.to_s] } }

      it 'filters groups by gid' do
        expect(subject).to contain_exactly(other_group)
      end
    end

    context 'with `top_level_only` argument' do
      let_it_be(:top_level_group) { create(:group, name: 'top-level-group') }
      let_it_be(:sub_group) { create(:group, name: 'sub_group', parent: top_level_group) }

      context 'with `top_level_only` argument provided' do
        let(:params) { { top_level_only: true } }

        it 'return only top level groups' do
          expect(subject).to contain_exactly(public_group, top_level_group)
        end
      end
    end

    context 'with `owned_only` argument' do
      let_it_be(:owned_group) { create(:group, name: 'with owner role', owners: user) }

      context 'with `owned_only` argument provided' do
        let(:params) { { owned_only: true } }

        it 'return only owned groups' do
          expect(subject).to contain_exactly(owned_group)
        end
      end
    end
  end
end
