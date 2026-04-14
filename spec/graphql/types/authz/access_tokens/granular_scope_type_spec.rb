# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Authz::AccessTokens::GranularScopeType, feature_category: :permissions do
  include GraphqlHelpers
  let(:fields) do
    %w[access namespace project permissions]
  end

  specify { expect(described_class.graphql_name).to eq('AccessTokenGranularScope') }

  specify { expect(described_class).to have_graphql_fields(fields) }

  describe 'access' do
    it 'has matching enum values' do
      expect(Types::Authz::AccessTokens::GranularScopeAccessEnum.values.keys.map(&:downcase))
        .to match_array(Authz::GranularScope.accesses.keys)
    end
  end

  describe '#project' do
    let_it_be(:project) { create(:project) }
    let_it_be(:group) { create(:group) }

    it 'returns the project when namespace is a ProjectNamespace' do
      scope = build(:granular_scope, namespace: project.project_namespace)

      expect(batch_sync { resolve_field(:project, scope, current_user: nil) }).to eq(project)
    end

    it 'returns nil when namespace is a Group' do
      scope = build(:granular_scope, namespace: group)

      expect(batch_sync { resolve_field(:project, scope, current_user: nil) }).to be_nil
    end

    it 'returns nil when namespace is nil' do
      scope = build(:granular_scope, namespace: nil)

      expect(batch_sync { resolve_field(:project, scope, current_user: nil) }).to be_nil
    end
  end
end
