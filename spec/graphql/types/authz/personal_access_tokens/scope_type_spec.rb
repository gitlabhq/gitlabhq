# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Authz::PersonalAccessTokens::ScopeType, feature_category: :permissions do
  specify { expect(described_class.graphql_name).to eq('PersonalAccessTokenScope') }

  it 'exposes all possible types' do
    expect(described_class.possible_types).to contain_exactly(
      Types::Authz::AccessTokens::LegacyScopeType,
      Types::Authz::AccessTokens::GranularScopeType
    )
  end

  describe '.resolve_type' do
    subject(:resolve_type) { described_class.resolve_type(object, {}) }

    context 'with a legacy scope' do
      let(:object) { 'api' }

      it { is_expected.to eq(Types::Authz::AccessTokens::LegacyScopeType) }
    end

    context 'with a granular scope' do
      let(:object) { build(:granular_scope) }

      it { is_expected.to eq(Types::Authz::AccessTokens::GranularScopeType) }
    end

    context 'with an unknown scope type' do
      let(:object) { nil }

      it 'raises an error' do
        expect { resolve_type }.to raise_error(
          ::Gitlab::Graphql::Errors::BaseError,
          /Unknown scope type/
        )
      end
    end
  end
end
