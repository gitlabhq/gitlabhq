# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['TerraformStateProtectionRule'], feature_category: :infrastructure_as_code do
  specify { expect(described_class.graphql_name).to eq('TerraformStateProtectionRule') }
  specify { expect(described_class.description).to be_present }
  specify { expect(described_class).to require_graphql_authorizations(:read_terraform_state) }

  describe 'id' do
    subject { described_class.fields['id'] }

    it { is_expected.to have_non_null_graphql_type(::Types::GlobalIDType[::Terraform::StateProtectionRule]) }
  end

  describe 'state_name' do
    subject { described_class.fields['stateName'] }

    it { is_expected.to have_non_null_graphql_type(GraphQL::Types::String) }
  end

  describe 'minimum_access_level_for_write' do
    subject { described_class.fields['minimumAccessLevelForWrite'] }

    it { is_expected.to have_non_null_graphql_type(Types::Terraform::StateProtectionRuleAccessLevelEnum) }
  end

  describe 'allowed_from' do
    subject { described_class.fields['allowedFrom'] }

    it { is_expected.to have_non_null_graphql_type(Types::Terraform::StateProtectionRuleAllowedFromEnum) }
  end
end
