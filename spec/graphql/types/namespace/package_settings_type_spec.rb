# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PackageSettings'] do
  specify { expect(described_class.graphql_name).to eq('PackageSettings') }

  specify { expect(described_class.description).to eq('Namespace-level Package Registry settings') }

  specify { expect(described_class).to require_graphql_authorizations(:read_package_settings) }

  describe 'maven_duplicate_exception_regex field' do
    subject { described_class.fields['mavenDuplicateExceptionRegex'] }

    it { is_expected.to have_graphql_type(Types::UntrustedRegexp) }
  end
end
