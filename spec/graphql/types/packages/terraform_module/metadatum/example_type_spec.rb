# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['TerraformModuleMetadataExample'], feature_category: :package_registry do
  it 'includes terraform module metadatum root fields' do
    expected_fields = %w[inputs outputs readme readme_html name]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
