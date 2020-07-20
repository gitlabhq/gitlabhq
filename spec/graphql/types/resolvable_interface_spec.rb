# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::ResolvableInterface do
  it 'exposes the expected fields' do
    expected_fields = %i[
      resolvable
      resolved
      resolved_at
      resolved_by
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
