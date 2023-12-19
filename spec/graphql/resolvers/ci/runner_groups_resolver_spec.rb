# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::RunnerGroupsResolver, feature_category: :fleet_visibility do
  include GraphqlHelpers

  let_it_be(:group1) { create(:group) }
  let_it_be(:runner) { create(:ci_runner, :group, groups: [group1]) }

  let(:args) { {} }

  subject(:response) { resolve_groups(args) }

  describe '#resolve' do
    context 'with authorized user', :enable_admin_mode do
      let(:current_user) { create(:user, :admin) }

      it 'returns a lazy value with all groups' do
        expect(response).to be_a(GraphQL::Execution::Lazy)
        expect(response.value).to contain_exactly(group1)
      end
    end

    context 'with unauthorized user' do
      let(:current_user) { create(:user) }

      it { is_expected.to be_nil }
    end
  end

  private

  def resolve_groups(args = {}, context = { current_user: current_user })
    resolve(described_class, obj: runner, args: args, ctx: context)
  end
end
