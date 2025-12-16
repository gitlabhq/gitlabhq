# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Authz::PersonalAccessTokens::PersonalAccessTokenType, feature_category: :permissions do
  let(:fields) do
    %w[id name description granular revoked active scopes last_used_ips last_used_at created_at expires_at]
  end

  specify { expect(described_class.graphql_name).to eq('PersonalAccessToken') }

  specify { expect(described_class).to have_graphql_fields(fields) }
end
