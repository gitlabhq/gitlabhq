# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ReleaseEvidence'] do
  specify { expect(described_class).to require_graphql_authorizations(:read_release_evidence) }

  it 'has the expected fields' do
    expected_fields = %w[
      id sha filepath collected_at
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
