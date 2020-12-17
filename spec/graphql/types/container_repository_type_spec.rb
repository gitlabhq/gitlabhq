# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ContainerRepository'] do
  fields = %i[id name path location created_at updated_at expiration_policy_started_at status tags_count can_delete expiration_policy_cleanup_status project]

  it { expect(described_class.graphql_name).to eq('ContainerRepository') }

  it { expect(described_class.description).to eq('A container repository') }

  it { expect(described_class).to require_graphql_authorizations(:read_container_image) }

  it { expect(described_class).to have_graphql_fields(fields) }

  describe 'status field' do
    subject { described_class.fields['status'] }

    it 'returns status enum' do
      is_expected.to have_graphql_type(Types::ContainerRepositoryStatusEnum)
    end
  end

  describe 'expiration_policy_cleanup_status field' do
    subject { described_class.fields['expirationPolicyCleanupStatus'] }

    it 'returns cleanup status enum' do
      is_expected.to have_graphql_type(Types::ContainerRepositoryCleanupStatusEnum)
    end
  end
end
