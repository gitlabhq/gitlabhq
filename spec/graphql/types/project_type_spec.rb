# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Project'] do
  specify { expect(described_class).to expose_permissions_using(Types::PermissionTypes::Project) }

  specify { expect(described_class.graphql_name).to eq('Project') }

  specify { expect(described_class).to require_graphql_authorizations(:read_project) }

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
      grafanaIntegration autocloseReferencedIssues suggestion_commit_message environments
      boards jira_import_status jira_imports services releases release
      alert_management_alerts alert_management_alert alert_management_alert_status_counts
      container_expiration_policy sast_ci_configuration service_desk_enabled service_desk_address
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
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

  describe 'merge_request field' do
    subject { described_class.fields['mergeRequest'] }

    it { is_expected.to have_graphql_type(Types::MergeRequestType) }
    it { is_expected.to have_graphql_resolver(Resolvers::MergeRequestsResolver.single) }
    it { is_expected.to have_graphql_arguments(:iid) }
  end

  describe 'merge_requests field' do
    subject { described_class.fields['mergeRequests'] }

    it { is_expected.to have_graphql_type(Types::MergeRequestType.connection_type) }
    it { is_expected.to have_graphql_resolver(Resolvers::MergeRequestsResolver) }

    it do
      is_expected.to have_graphql_arguments(:iids,
                                            :source_branches,
                                            :target_branches,
                                            :state,
                                            :labels,
                                            :before,
                                            :after,
                                            :first,
                                            :last
                                           )
    end
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

  describe 'environments field' do
    subject { described_class.fields['environments'] }

    it { is_expected.to have_graphql_type(Types::EnvironmentType.connection_type) }
    it { is_expected.to have_graphql_resolver(Resolvers::EnvironmentsResolver) }
  end

  describe 'members field' do
    subject { described_class.fields['projectMembers'] }

    it { is_expected.to have_graphql_type(Types::ProjectMemberType.connection_type) }
    it { is_expected.to have_graphql_resolver(Resolvers::ProjectMembersResolver) }
  end

  describe 'boards field' do
    subject { described_class.fields['boards'] }

    it { is_expected.to have_graphql_type(Types::BoardType.connection_type) }
  end

  describe 'jira_imports field' do
    subject { described_class.fields['jiraImports'] }

    it { is_expected.to have_graphql_type(Types::JiraImportType.connection_type) }
  end

  describe 'services field' do
    subject { described_class.fields['services'] }

    it { is_expected.to have_graphql_type(Types::Projects::ServiceType.connection_type) }
  end

  describe 'releases field' do
    subject { described_class.fields['release'] }

    it { is_expected.to have_graphql_type(Types::ReleaseType) }
    it { is_expected.to have_graphql_resolver(Resolvers::ReleaseResolver) }
  end

  describe 'release field' do
    subject { described_class.fields['releases'] }

    it { is_expected.to have_graphql_type(Types::ReleaseType.connection_type) }
    it { is_expected.to have_graphql_resolver(Resolvers::ReleasesResolver) }
  end

  describe 'container expiration policy field' do
    subject { described_class.fields['containerExpirationPolicy'] }

    it { is_expected.to have_graphql_type(Types::ContainerExpirationPolicyType) }
  end

  describe 'sast_ci_configuration' do
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user) }
    let_it_be(:query) do
      %(
        query {
            project(fullPath: "#{project.full_path}") {
                sastCiConfiguration {
                  global {
                    nodes {
                      type
                      options {
                        nodes {
                          label
                          value
                        }
                      }
                      field
                      label
                      defaultValue
                      value
                    }
                  }
                  pipeline {
                    nodes {
                      type
                      options {
                        nodes {
                          label
                          value
                        }
                      }
                      field
                      label
                      defaultValue
                      value
                    }
                  }
                  analyzers {
                    nodes {
                      name
                      label
                      enabled
                    }
                  }
                }
              }
        }
      )
    end

    subject { GitlabSchema.execute(query, context: { current_user: user }).as_json }

    before do
      project.add_developer(user)
    end

    it "returns the project's sast configuration for global variables" do
      query_result = subject.dig('data', 'project', 'sastCiConfiguration', 'global', 'nodes')
      first_config = query_result.first
      fourth_config = query_result[3]
      expect(first_config['type']).to eq('string')
      expect(first_config['field']).to eq('SECURE_ANALYZERS_PREFIX')
      expect(first_config['label']).to eq('Image prefix')
      expect(first_config['defaultValue']).to eq('registry.gitlab.com/gitlab-org/security-products/analyzers')
      expect(first_config['value']).to eq('')
      expect(first_config['options']).to be_nil
      expect(fourth_config['options']['nodes']).to match([{ "value" => "true", "label" => "true (disables SAST)" },
                                                          { "value" => "false", "label" => "false (enables SAST)" }])
    end

    it "returns the project's sast configuration for pipeline variables" do
      configuration = subject.dig('data', 'project', 'sastCiConfiguration', 'pipeline', 'nodes').first
      expect(configuration['type']).to eq('dropdown')
      expect(configuration['field']).to eq('stage')
      expect(configuration['label']).to eq('Stage')
      expect(configuration['defaultValue']).to eq('test')
      expect(configuration['value']).to eq('')
    end

    it "returns the project's sast configuration for analyzer variables" do
      configuration = subject.dig('data', 'project', 'sastCiConfiguration', 'analyzers', 'nodes').first
      expect(configuration['name']).to eq('brakeman')
      expect(configuration['label']).to eq('Brakeman')
      expect(configuration['enabled']).to eq(true)
    end
  end

  it_behaves_like 'a GraphQL type with labels'
end
