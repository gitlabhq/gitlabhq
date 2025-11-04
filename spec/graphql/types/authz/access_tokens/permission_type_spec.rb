# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Authz::AccessTokens::PermissionType, feature_category: :permissions do
  let(:fields) do
    %w[name description action resource]
  end

  specify { expect(described_class.graphql_name).to eq('AccessTokenPermission') }

  specify { expect(described_class).to have_graphql_fields(fields) }
end
