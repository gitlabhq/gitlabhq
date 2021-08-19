# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PackageDependencyLink'] do
  it 'includes package file fields' do
    expected_fields = %w[
      id dependency_type dependency metadata
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
