# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ContainerRepositoryDetails'], feature_category: :container_registry do
  fields = %i[id name path location created_at updated_at expiration_policy_started_at
    status tags_count expiration_policy_cleanup_status tags size manifest
    project migration_state last_cleanup_deleted_tags_count user_permissions last_published_at
    protection_rule_exists]

  it { expect(described_class.graphql_name).to eq('ContainerRepositoryDetails') }

  it { expect(described_class.description).to eq('Details of a container repository') }

  it { expect(described_class).to require_graphql_authorizations(:read_container_image) }

  it { expect(described_class).to have_graphql_fields(fields) }

  describe 'tags field' do
    subject { described_class.fields['tags'] }

    it 'returns tags connection type' do
      is_expected.to have_graphql_type(Types::ContainerRegistry::ContainerRepositoryTagType.connection_type)
    end
  end
end
