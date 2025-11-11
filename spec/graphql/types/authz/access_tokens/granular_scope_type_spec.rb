# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Authz::AccessTokens::GranularScopeType, feature_category: :permissions do
  let(:fields) do
    %w[access namespace permissions]
  end

  specify { expect(described_class.graphql_name).to eq('AccessTokenGranularScope') }

  specify { expect(described_class).to have_graphql_fields(fields) }
end
