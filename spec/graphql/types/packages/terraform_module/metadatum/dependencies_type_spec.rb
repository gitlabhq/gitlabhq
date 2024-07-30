# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['TerraformModuleMetadataDependencies'], feature_category: :package_registry do
  it 'includes terraform module metadatum dependencies fields' do
    expected_fields = %w[modules providers]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
