# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PackageDetailsType'] do
  it 'includes all the package fields' do
    expected_fields = %w[
      id name version created_at updated_at package_type tags project
      pipelines versions package_files dependency_links
      npm_url maven_url conan_url nuget_url pypi_url pypi_setup_url
      composer_url composer_config_repository_url
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  it 'overrides the pipelines field' do
    field = described_class.fields['pipelines']

    expect(field).to have_graphql_type(Types::Ci::PipelineType.connection_type)
    expect(field).to have_graphql_extension(Gitlab::Graphql::Extensions::ExternallyPaginatedArrayExtension)
    expect(field).to have_graphql_resolver(Resolvers::PackagePipelinesResolver)
    expect(field).not_to be_connection
  end
end
