# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Discussion'] do
  it 'exposes the expected fields' do
    expected_fields = %i[
      created_at
      id
      notes
      reply_id
      resolvable
      resolved
      resolved_at
      resolved_by
      noteable
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  specify { expect(described_class).to require_graphql_authorizations(:read_note) }
end
