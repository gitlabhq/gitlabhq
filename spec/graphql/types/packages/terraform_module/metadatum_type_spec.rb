# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['TerraformModuleMetadata'], feature_category: :package_registry do
  specify { expect(described_class).to require_graphql_authorizations(:read_package) }

  it 'includes terraform module metadatum fields' do
    expected_fields = %w[id created_at updated_at fields]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
