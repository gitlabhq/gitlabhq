# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['PackagesProtectionRule'], feature_category: :package_registry do
  include GraphqlHelpers

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

  describe 'minimum_access_level_for_delete' do
    subject { described_class.fields['minimumAccessLevelForDelete'] }

    it { is_expected.to have_nullable_graphql_type(Types::Packages::Protection::RuleAccessLevelForDeleteEnum) }

    describe 'resolve field' do
      let_it_be(:package_protection_rule) { create(:package_protection_rule) }
      let(:user) { package_protection_rule.project.owner }

      subject do
        resolve_field(:minimum_access_level_for_delete, package_protection_rule, current_user: user,
          object_type: described_class)
      end

      it { is_expected.to eq 'owner' }

      context 'when the feature flag `packages_protected_packages_delete` is disabled' do
        before do
          stub_feature_flags(packages_protected_packages_delete: false)
        end

        it { is_expected.to be_nil }
      end
    end
  end

  describe 'minimum_access_level_for_push' do
    subject { described_class.fields['minimumAccessLevelForPush'] }

    it { is_expected.to have_nullable_graphql_type(Types::Packages::Protection::RuleAccessLevelEnum) }
  end
end
