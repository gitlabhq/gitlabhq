# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['ReleaseEvidence'] do
  it { expect(described_class).to require_graphql_authorizations(:download_code) }

  it 'has the expected fields' do
    expected_fields = %w[
      id sha filepath collected_at
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
