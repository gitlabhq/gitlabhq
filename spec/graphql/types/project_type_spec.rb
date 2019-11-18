# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['Project'] do
  it { expect(described_class).to expose_permissions_using(Types::PermissionTypes::Project) }

  it { expect(described_class.graphql_name).to eq('Project') }

  it { expect(described_class).to require_graphql_authorizations(:read_project) }

  it 'has the expected fields' do
    expected_fields = %w[
      user_permissions id full_path path name_with_namespace
      name description description_html tag_list ssh_url_to_repo
      http_url_to_repo web_url star_count forks_count
      created_at last_activity_at archived visibility
      container_registry_enabled shared_runners_enabled
      lfs_enabled merge_requests_ff_only_enabled avatar_url
      issues_enabled merge_requests_enabled wiki_enabled
      snippets_enabled jobs_enabled public_jobs open_issues_count import_status
      only_allow_merge_if_pipeline_succeeds request_access_enabled
      only_allow_merge_if_all_discussions_are_resolved printing_merge_request_link_enabled
      namespace group statistics repository merge_requests merge_request issues
      issue pipelines
      removeSourceBranchAfterMerge
    ]

    is_expected.to have_graphql_fields(*expected_fields)
  end

  describe 'issue field' do
    subject { described_class.fields['issue'] }

    it 'returns issue' do
      is_expected.to have_graphql_type(Types::IssueType)
      is_expected.to have_graphql_resolver(Resolvers::IssuesResolver.single)
    end
  end

  describe 'issues field' do
    subject { described_class.fields['issues'] }

    it 'returns issue' do
      is_expected.to have_graphql_type(Types::IssueType.connection_type)
      is_expected.to have_graphql_resolver(Resolvers::IssuesResolver)
    end
  end

  describe 'merge_requests field' do
    subject { described_class.fields['mergeRequest'] }

    it 'returns merge requests' do
      is_expected.to have_graphql_type(Types::MergeRequestType)
      is_expected.to have_graphql_resolver(Resolvers::MergeRequestsResolver.single)
    end
  end

  describe 'merge_request field' do
    subject { described_class.fields['mergeRequests'] }

    it 'returns merge request' do
      is_expected.to have_graphql_type(Types::MergeRequestType.connection_type)
      is_expected.to have_graphql_resolver(Resolvers::MergeRequestsResolver)
    end
  end
end
