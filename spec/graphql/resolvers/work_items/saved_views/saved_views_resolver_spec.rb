# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::WorkItems::SavedViews::SavedViewsResolver, feature_category: :portfolio_management do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:saved_view1) { create(:saved_view, namespace: group, name: 'SavedView1') }
  let_it_be(:saved_view2) { create(:saved_view, namespace: group, name: 'SavedView2') }

  let(:args) { {} }
  let(:ctx) { { current_user: user } }

  subject(:result) do
    resolve(described_class, obj: group, args: args, ctx: ctx, arg_style: :internal)
  end

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::WorkItems::SavedViews::SavedViewType.connection_type)
  end

  describe 'arguments' do
    describe 'id argument prepare' do
      it 'converts GlobalID to model_id' do
        id_arg = described_class.arguments['id']
        gid = saved_view1.to_global_id

        prepared_value = id_arg.prepare.call(gid, nil)

        expect(prepared_value).to eq(saved_view1.id.to_s)
      end
    end
  end

  describe '#resolve' do
    it 'returns saved views for the namespace' do
      expect(result).to contain_exactly(saved_view1, saved_view2)
    end

    context 'with id argument' do
      let(:args) { { id: saved_view1.id } }

      it 'returns the specified saved view' do
        expect(result).to contain_exactly(saved_view1)
      end
    end

    context 'with search argument' do
      let(:args) { { search: 'SavedView1' } }

      it 'returns matching saved views' do
        expect(result).to contain_exactly(saved_view1)
      end
    end

    context 'with subscribed_only argument' do
      let!(:user_saved_view) { create(:user_saved_view, user: user, saved_view: saved_view1, namespace: group) }
      let(:args) { { subscribed_only: true } }

      it 'returns only subscribed saved views' do
        expect(result).to contain_exactly(saved_view1)
      end
    end

    context 'with sort argument' do
      let(:args) { { sort: :id } }

      it 'returns saved views sorted' do
        expect(result.to_a).to match_array([saved_view2, saved_view1])
      end
    end
  end
end
