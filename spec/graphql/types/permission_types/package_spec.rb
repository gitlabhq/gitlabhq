# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PackagePermissions'], feature_category: :package_registry do
  it 'has the expected fields' do
    expected_permissions = [:destroy_package]

    expect(described_class).to have_graphql_fields(expected_permissions).only
  end
end
