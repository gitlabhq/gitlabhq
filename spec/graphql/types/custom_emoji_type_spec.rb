# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['CustomEmoji'] do
  expected_fields = %w[
    id
    name
    url
    external
    created_at
    user_permissions
  ]

  specify { expect(described_class.graphql_name).to eq('CustomEmoji') }

  specify { expect(described_class).to require_graphql_authorizations(:read_custom_emoji) }

  specify { expect(described_class).to have_graphql_fields(*expected_fields) }

  specify { expect(described_class).to expose_permissions_using(Types::PermissionTypes::CustomEmoji) }
end
