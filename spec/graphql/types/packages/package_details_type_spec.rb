# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PackageDetailsType'] do
  specify { expect(described_class.description).to eq('Represents a package details in the Package Registry') }

  specify { expect(described_class).to require_graphql_authorizations(:read_package) }

  it 'includes all the package fields' do
    expected_fields = %w[
      id name version created_at updated_at package_type tags project
      pipelines versions package_files dependency_links public_package
      npm_url maven_url conan_url nuget_url pypi_url pypi_setup_url
      composer_url composer_config_repository_url
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
