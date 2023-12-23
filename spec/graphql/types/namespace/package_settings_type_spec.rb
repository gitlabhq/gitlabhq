# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PackageSettings'], feature_category: :package_registry do
  specify { expect(described_class.graphql_name).to eq('PackageSettings') }

  specify { expect(described_class.description).to eq('Namespace-level Package Registry settings') }

  specify { expect(described_class).to require_graphql_authorizations(:admin_package) }

  describe 'maven_duplicate_exception_regex field' do
    subject { described_class.fields['mavenDuplicateExceptionRegex'] }

    it { is_expected.to have_graphql_type(Types::UntrustedRegexp) }
  end

  it 'includes package setting fields' do
    expected_fields = %w[
      maven_duplicates_allowed
      maven_duplicate_exception_regex
      generic_duplicates_allowed
      generic_duplicate_exception_regex
      nuget_duplicates_allowed
      nuget_duplicate_exception_regex
      maven_package_requests_forwarding
      lock_maven_package_requests_forwarding
      npm_package_requests_forwarding
      lock_npm_package_requests_forwarding
      pypi_package_requests_forwarding
      lock_pypi_package_requests_forwarding
      maven_package_requests_forwarding_locked
      npm_package_requests_forwarding_locked
      pypi_package_requests_forwarding_locked
      nuget_symbol_server_enabled
      terraform_module_duplicates_allowed
      terraform_module_duplicate_exception_regex
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
