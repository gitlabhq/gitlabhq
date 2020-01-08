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
      issue pipelines removeSourceBranchAfterMerge sentryDetailedError snippets
      grafanaIntegration autocloseReferencedIssues
    ]

    is_expected.to include_graphql_fields(*expected_fields)
  end

  describe 'issue field' do
    subject { described_class.fields['issue'] }

    it { is_expected.to have_graphql_type(Types::IssueType) }
    it { is_expected.to have_graphql_resolver(Resolvers::IssuesResolver.single) }
  end

  describe 'issues field' do
    subject { described_class.fields['issues'] }

    it { is_expected.to have_graphql_type(Types::IssueType.connection_type) }
    it { is_expected.to have_graphql_resolver(Resolvers::IssuesResolver) }
  end

  describe 'merge_requests field' do
    subject { described_class.fields['mergeRequest'] }

    it { is_expected.to have_graphql_type(Types::MergeRequestType) }
    it { is_expected.to have_graphql_resolver(Resolvers::MergeRequestsResolver.single) }
  end

  describe 'merge_request field' do
    subject { described_class.fields['mergeRequests'] }

    it { is_expected.to have_graphql_type(Types::MergeRequestType.connection_type) }
    it { is_expected.to have_graphql_resolver(Resolvers::MergeRequestsResolver) }
  end

  describe 'snippets field' do
    subject { described_class.fields['snippets'] }

    it { is_expected.to have_graphql_type(Types::SnippetType.connection_type) }
    it { is_expected.to have_graphql_resolver(Resolvers::Projects::SnippetsResolver) }
  end

  describe 'grafana_integration field' do
    subject { described_class.fields['grafanaIntegration'] }

    it { is_expected.to have_graphql_type(Types::GrafanaIntegrationType) }
    it { is_expected.to have_graphql_resolver(Resolvers::Projects::GrafanaIntegrationResolver) }
  end
end
