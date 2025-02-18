# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::GroupEnvironmentScopesResolver, feature_category: :ci_variables do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let(:group) { create(:group) }

  context "with a group" do
    let(:expected_environment_scopes) do
      %w[environment1 environment2 environment3 environment4 environment5 environment6]
    end

    before do
      group.add_developer(current_user)
      expected_environment_scopes.each_with_index do |env, index|
        create(:ci_group_variable, group: group, key: "var#{index + 1}", environment_scope: env)
      end
    end

    describe '#resolve' do
      it 'finds all environment scopes' do
        expect(resolve_environment_scopes.map(&:name)).to match_array(
          expected_environment_scopes
        )
      end
    end
  end

  context 'without a group' do
    describe '#resolve' do
      it 'rails to find any environment scopes' do
        expect(resolve_environment_scopes.map(&:name)).to be_empty
      end
    end
  end

  def resolve_environment_scopes(args = {}, context = { current_user: current_user })
    resolve(described_class, obj: group, args: args, ctx: context)
  end
end
