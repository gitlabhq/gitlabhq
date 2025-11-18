# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Authz::AccessTokens::LegacyScopeType, feature_category: :permissions do
  let(:fields) do
    %w[value]
  end

  specify { expect(described_class.graphql_name).to eq('AccessTokenLegacyScope') }

  specify { expect(described_class).to have_graphql_fields(fields) }
end
