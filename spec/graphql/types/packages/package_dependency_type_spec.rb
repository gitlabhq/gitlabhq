# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PackageDependency'], feature_category: :package_registry do
  it 'includes package file fields' do
    expected_fields = %w[
      id name version_pattern
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
