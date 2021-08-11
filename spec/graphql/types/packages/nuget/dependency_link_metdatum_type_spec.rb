# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['NugetDependencyLinkMetadata'] do
  it 'includes nuget dependency link metadatum fields' do
    expected_fields = %w[
      id target_framework
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
