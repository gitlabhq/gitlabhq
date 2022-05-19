# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PackageBase'] do
  specify { expect(described_class.description).to eq('Represents a package in the Package Registry') }

  specify { expect(described_class).to require_graphql_authorizations(:read_package) }

  it 'includes all expected fields' do
    expected_fields = %w[
      id name version package_type
      created_at updated_at
      project
      tags metadata
      status can_destroy
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
