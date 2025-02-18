# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ContainerProtectionTagRule'], feature_category: :container_registry do
  specify { expect(described_class.graphql_name).to eq('ContainerProtectionTagRule') }

  specify { expect(described_class.description).to be_present }

  specify { expect(described_class).to require_graphql_authorizations(:admin_container_image) }

  describe 'id' do
    subject { described_class.fields['id'] }

    it { is_expected.to have_non_null_graphql_type(::Types::GlobalIDType[::ContainerRegistry::Protection::TagRule]) }
  end

  describe 'tag_name_pattern' do
    subject { described_class.fields['tagNamePattern'] }

    it { is_expected.to have_non_null_graphql_type(GraphQL::Types::String) }
  end

  describe 'minimum_access_level_for_push' do
    subject { described_class.fields['minimumAccessLevelForPush'] }

    it { is_expected.to have_nullable_graphql_type(Types::ContainerRegistry::Protection::TagRuleAccessLevelEnum) }
  end

  describe 'minimum_access_level_for_delete' do
    subject { described_class.fields['minimumAccessLevelForDelete'] }

    it { is_expected.to have_nullable_graphql_type(Types::ContainerRegistry::Protection::TagRuleAccessLevelEnum) }
  end
end
