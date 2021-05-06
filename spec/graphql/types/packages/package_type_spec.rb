# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Package'] do
  it 'includes all the package fields' do
    expected_fields = %w[
      id name version package_type
      created_at updated_at
      project
      tags pipelines metadata versions
      status
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
