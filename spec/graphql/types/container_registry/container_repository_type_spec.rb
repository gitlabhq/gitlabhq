# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ContainerRepository'], feature_category: :container_registry do
  include GraphqlHelpers

  fields = %i[id name path location created_at updated_at expiration_policy_started_at
    status tags_count expiration_policy_cleanup_status project
    migration_state last_cleanup_deleted_tags_count user_permissions protection_rule_exists]

  it { expect(described_class.graphql_name).to eq('ContainerRepository') }

  it { expect(described_class.description).to eq('A container repository') }

  it { expect(described_class).to require_graphql_authorizations(:read_container_image) }

  it { expect(described_class).to have_graphql_fields(fields) }

  it { expect(described_class).to expose_permissions_using(Types::PermissionTypes::ContainerRepository) }

  describe 'status field' do
    subject { described_class.fields['status'] }

    it 'returns status enum' do
      is_expected.to have_graphql_type(Types::ContainerRegistry::ContainerRepositoryStatusEnum)
    end
  end

  describe 'expiration_policy_cleanup_status field' do
    subject { described_class.fields['expirationPolicyCleanupStatus'] }

    it 'returns cleanup status enum' do
      is_expected.to have_graphql_type(Types::ContainerRegistry::ContainerRepositoryCleanupStatusEnum)
    end
  end

  describe '#migration_state' do
    it 'returns an empty string' do
      container_repository = described_class.allocate
      expect(container_repository.migration_state).to eq('')
    end
  end
end
