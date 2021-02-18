# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PackageWithoutVersions'] do
  it 'includes all the package fields' do
    expected_fields = %w[
      id name version created_at updated_at package_type tags project pipelines
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
