# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PypiMetadata'] do
  it 'includes pypi metadatum fields' do
    expected_fields = %w[
      id required_python
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
