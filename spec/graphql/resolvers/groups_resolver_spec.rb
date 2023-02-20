# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::GroupsResolver, feature_category: :subgroups do
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
  end
end
