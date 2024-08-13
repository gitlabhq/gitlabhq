# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['TerraformModuleMetadataRoot'], feature_category: :package_registry do
  it 'includes terraform module metadatum root fields' do
    expected_fields = %w[dependencies inputs outputs readme readme_html resources]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
