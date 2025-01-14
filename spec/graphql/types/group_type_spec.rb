# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Group'], feature_category: :groups_and_projects do
  include GraphqlHelpers

  specify { expect(described_class).to expose_permissions_using(Types::PermissionTypes::Group) }

  specify { expect(described_class.graphql_name).to eq('Group') }

  specify { expect(described_class).to require_graphql_authorizations(:read_group) }

  it 'has the expected fields' do
    expected_fields = %w[
      id name path full_name full_path description description_html visibility
      lfs_enabled request_access_enabled projects root_storage_statistics
      web_url avatar_url share_with_group_lock project_creation_level
      descendant_groups_count group_members_count projects_count
      subgroup_creation_level require_two_factor_authentication
      two_factor_grace_period auto_devops_enabled emails_disabled emails_enabled
      mentions_disabled parent boards milestones group_members
      merge_requests container_repositories container_repositories_count
      packages dependency_proxy_setting dependency_proxy_manifests
      dependency_proxy_blobs dependency_proxy_image_count max_access_level
      dependency_proxy_blob_count dependency_proxy_total_size dependency_proxy_total_size_in_bytes
      dependency_proxy_image_prefix dependency_proxy_image_ttl_policy
      shared_runners_setting timelogs organization_state_counts organizations
      contact_state_counts contacts work_item_types
      recent_issue_boards ci_variables releases environment_scopes work_items autocomplete_users
      lock_math_rendering_limits_enabled math_rendering_limits_enabled created_at updated_at
      organization_edit_path is_linked_to_subscription allowed_custom_statuses
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

  describe 'timelogs field' do
    subject { described_class.fields['timelogs'] }

    it 'finds timelogs between start time and end time' do
      is_expected.to have_graphql_resolver(Resolvers::TimelogResolver)
      is_expected.to have_non_null_graphql_type(Types::TimelogType.connection_type)
    end
  end

  describe 'contact_state_counts field' do
    subject { described_class.fields['contactStateCounts'] }

    it { is_expected.to have_graphql_type(Types::CustomerRelations::ContactStateCountsType) }
    it { is_expected.to have_graphql_resolver(Resolvers::Crm::ContactStateCountsResolver) }
  end

  describe 'organization_state_counts field' do
    subject { described_class.fields['organizationStateCounts'] }

    it { is_expected.to have_graphql_type(Types::CustomerRelations::OrganizationStateCountsType) }
    it { is_expected.to have_graphql_resolver(Resolvers::Crm::OrganizationStateCountsResolver) }
  end

  describe 'releases field' do
    subject { described_class.fields['releases'] }

    it { is_expected.to have_graphql_type(Types::ReleaseType.connection_type) }
    it { is_expected.to have_graphql_resolver(Resolvers::GroupReleasesResolver) }
  end

  describe 'work_items field' do
    subject { described_class.fields['workItems'] }

    it { is_expected.to have_graphql_type(Types::WorkItemType.connection_type) }
    it { is_expected.to have_graphql_resolver(Resolvers::Namespaces::WorkItemsResolver) }
  end

  it_behaves_like 'a GraphQL type with labels' do
    let(:labels_resolver_arguments) do
      [:search_term, :includeAncestorGroups, :includeDescendantGroups, :onlyGroupLabels, :searchIn, :title]
    end
  end

  describe 'milestones' do
    let(:user) { create(:user) }
    let(:subgroup) { create(:group, parent: create(:group)) }
    let(:query) do
      %(
        query {
          group(fullPath: "#{subgroup.full_path}") {
            milestones {
              nodes {
                id
                title
                projectMilestone
                groupMilestone
                subgroupMilestone
              }
            }
          }
        }
      )
    end

    def clean_state_query
      run_with_clean_state(query, context: { current_user: user })
    end

    it 'avoids N+1 queries' do
      subgroup.add_reporter(user)

      create(:milestone, group: subgroup)

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) { clean_state_query }

      create_list(:milestone, 2, group: subgroup)

      expect { clean_state_query }.not_to exceed_all_query_limit(control)
    end
  end

  describe 'custom emoji' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: group) }
    let_it_be(:custom_emoji) { create(:custom_emoji, group: group) }
    let_it_be(:custom_emoji_subgroup) { create(:custom_emoji, group: subgroup) }
    let(:query) do
      %(
        query {
          group(fullPath: "#{subgroup.full_path}") {
            customEmoji(includeAncestorGroups: true) {
              nodes {
                id
              }
            }
          }
        }
      )
    end

    before_all do
      group.add_reporter(user)
    end

    describe 'when includeAncestorGroups is true' do
      it 'returns emoji from ancestor groups' do
        result = GitlabSchema.execute(query, context: { current_user: user }).as_json

        expect(result.dig('data', 'group', 'customEmoji', 'nodes').count).to eq(2)
      end
    end

    it 'avoids N+1 queries' do
      control = ActiveRecord::QueryRecorder.new do
        GitlabSchema.execute(query, context: { current_user: user })
      end

      create_list(:custom_emoji, 3, group: group)

      expect { GitlabSchema.execute(query, context: { current_user: user }) }.not_to exceed_query_limit(control)
    end
  end

  describe 'emailsDisabled' do
    let_it_be(:group) { create(:group) }

    let(:query) do
      %(
        query {
          group(fullPath: "#{group.full_path}") {
            emailsDisabled
          }
        }
      )
    end

    subject(:result) do
      result = GitlabSchema.execute(query).as_json
      result.dig('data', 'group', 'emailsDisabled')
    end

    it 'is not a deprecated field' do
      expect(described_class.fields['emailsDisabled'].deprecation).to be_nil
    end

    describe 'when emails_enabled is true' do
      before do
        group.update!(emails_enabled: true)
      end

      it { is_expected.to eq(false) }
    end

    describe 'when emails_enabled is false' do
      before do
        group.update!(emails_enabled: false)
      end

      it { is_expected.to eq(true) }
    end
  end

  describe 'emailsEnabled' do
    let_it_be(:group) { create(:group) }

    let(:query) do
      %(
        query {
          group(fullPath: "#{group.full_path}") {
            emailsEnabled
          }
        }
      )
    end

    subject(:result) do
      result = GitlabSchema.execute(query).as_json
      result.dig('data', 'group', 'emailsEnabled')
    end

    it 'is not a deprecated field' do
      expect(described_class.fields['emailsEnabled'].deprecation).to be_nil
    end

    describe 'when emails_enabled is true' do
      before do
        group.update!(emails_enabled: true)
      end

      it { is_expected.to eq(true) }
    end

    describe 'when emails_enabled is false' do
      before do
        group.update!(emails_enabled: false)
      end

      it { is_expected.to eq(false) }
    end
  end

  describe 'organizationEditPath' do
    let_it_be(:user) { create(:user) }
    let_it_be(:organization) { create(:organization) }
    let(:query) do
      %(
        query {
          group(fullPath: "#{group.full_path}") {
            organizationEditPath
          }
        }
      )
    end

    let(:response) { GitlabSchema.execute(query, context: { current_user: user }).as_json }

    subject(:organization_edit_path) { response.dig('data', 'group', 'organizationEditPath') }

    context 'when group has an organization associated with it' do
      let_it_be(:group) { create(:group, :public, organization: organization) }

      it 'returns edit path scoped to organization' do
        expect(organization_edit_path).to eq(
          "/-/organizations/#{organization.path}/groups/#{group.full_path}/edit"
        )
      end
    end
  end
end
