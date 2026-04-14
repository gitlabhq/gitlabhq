# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Terraform::StateProtectionRulesResolver, feature_category: :infrastructure_as_code do
  include GraphqlHelpers

  it 'has the correct GraphQL type' do
    expect(described_class).to have_nullable_graphql_type(Types::Terraform::StateProtectionRuleType.connection_type)
  end

  describe '#resolve' do
    let_it_be(:project) { create(:project) }
    let_it_be(:protection_rule) { create(:terraform_state_protection_rule, project: project) }
    let_it_be(:other_rule) { create(:terraform_state_protection_rule) }

    let(:ctx) { Hash(current_user: user) }
    let(:user) { create(:user, developer_of: project) }

    subject(:result) { resolve(described_class, obj: project, ctx: ctx) }

    it 'returns protection rules associated with the project' do
      expect(result).to contain_exactly(protection_rule)
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(protected_terraform_states: false)
      end

      it { is_expected.to be_empty }
    end
  end
end
