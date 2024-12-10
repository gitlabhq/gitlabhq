# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ContainerProtectionRepositoryRule'], feature_category: :container_registry do
  specify { expect(described_class.graphql_name).to eq('ContainerProtectionRepositoryRule') }

  specify { expect(described_class.description).to be_present }

  specify { expect(described_class).to require_graphql_authorizations(:admin_container_image) }

  describe 'id' do
    subject { described_class.fields['id'] }

    it { is_expected.to have_non_null_graphql_type(::Types::GlobalIDType[::ContainerRegistry::Protection::Rule]) }
  end

  describe 'repository_path_pattern' do
    subject { described_class.fields['repositoryPathPattern'] }

    it { is_expected.to have_non_null_graphql_type(GraphQL::Types::String) }
  end

  describe 'minimum_access_level_for_push' do
    subject { described_class.fields['minimumAccessLevelForPush'] }

    it { is_expected.to have_nullable_graphql_type(Types::ContainerRegistry::Protection::RuleAccessLevelEnum) }
  end

  describe 'minimum_access_level_for_delete' do
    subject { described_class.fields['minimumAccessLevelForDelete'] }

    it { is_expected.to have_nullable_graphql_type(Types::ContainerRegistry::Protection::RuleAccessLevelEnum) }
  end
end
