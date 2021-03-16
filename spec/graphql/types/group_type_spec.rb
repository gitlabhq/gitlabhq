# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Group'] do
  specify { expect(described_class).to expose_permissions_using(Types::PermissionTypes::Group) }

  specify { expect(described_class.graphql_name).to eq('Group') }

  specify { expect(described_class).to require_graphql_authorizations(:read_group) }

  it 'has the expected fields' do
    expected_fields = %w[
      id name path full_name full_path description description_html visibility
      lfs_enabled request_access_enabled projects root_storage_statistics
      web_url avatar_url share_with_group_lock project_creation_level
      subgroup_creation_level require_two_factor_authentication
      two_factor_grace_period auto_devops_enabled emails_disabled
      mentions_disabled parent boards milestones group_members
      merge_requests container_repositories container_repositories_count
      packages
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  describe 'boards field' do
    subject { described_class.fields['boards'] }

    it 'returns boards' do
      is_expected.to have_graphql_type(Types::BoardType.connection_type)
    end
  end

  describe 'members field' do
    subject { described_class.fields['groupMembers'] }

    it { is_expected.to have_graphql_type(Types::GroupMemberType.connection_type) }
    it { is_expected.to have_graphql_resolver(Resolvers::GroupMembersResolver) }
  end

  it_behaves_like 'a GraphQL type with labels' do
    let(:labels_resolver_arguments) { [:search_term, :includeAncestorGroups, :includeDescendantGroups, :onlyGroupLabels] }
  end
end
