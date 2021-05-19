# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['NugetMetadata'] do
  it 'includes nuget metadatum fields' do
    expected_fields = %w[
      id license_url project_url icon_url
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
