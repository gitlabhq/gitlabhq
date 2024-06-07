# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PackagesProtectionRule'], feature_category: :package_registry do
  specify { expect(described_class.graphql_name).to eq('PackagesProtectionRule') }

  specify { expect(described_class.description).to be_present }

  specify { expect(described_class).to require_graphql_authorizations(:admin_package) }

  describe 'id' do
    subject { described_class.fields['id'] }

    it { is_expected.to have_non_null_graphql_type(::Types::GlobalIDType[::Packages::Protection::Rule]) }
  end

  describe 'package_name_pattern' do
    subject { described_class.fields['packageNamePattern'] }

    it { is_expected.to have_non_null_graphql_type(GraphQL::Types::String) }
  end

  describe 'package_type' do
    subject { described_class.fields['packageType'] }

    it { is_expected.to have_non_null_graphql_type(Types::Packages::Protection::RulePackageTypeEnum) }
  end

  describe 'minimum_access_level_for_push' do
    subject { described_class.fields['minimumAccessLevelForPush'] }

    it { is_expected.to have_non_null_graphql_type(Types::Packages::Protection::RuleAccessLevelEnum) }
  end
end
