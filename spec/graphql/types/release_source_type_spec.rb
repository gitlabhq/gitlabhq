# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ReleaseSource'] do
  it { expect(described_class).to require_graphql_authorizations(:read_code) }

  it 'has the expected fields' do
    expected_fields = %w[
      format url
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
