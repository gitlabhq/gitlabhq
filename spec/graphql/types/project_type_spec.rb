# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Project'] do
  include GraphqlHelpers
  include Ci::TemplateHelpers

  specify { expect(described_class).to expose_permissions_using(Types::PermissionTypes::Project) }

  specify { expect(described_class.graphql_name).to eq('Project') }

  specify { expect(described_class).to require_graphql_authorizations(:read_project) }

  it 'has the expected fields' do
    expected_fields = %w[
      user_permissions id full_path path name_with_namespace
      name description description_html tag_list topics ssh_url_to_repo
      http_url_to_repo web_url star_count forks_count
      created_at last_activity_at archived visibility
      container_registry_enabled shared_runners_enabled
      lfs_enabled merge_requests_ff_only_enabled avatar_url
      issues_enabled merge_requests_enabled wiki_enabled
      snippets_enabled jobs_enabled public_jobs open_issues_count import_status
      only_allow_merge_if_pipeline_succeeds request_access_enabled
      only_allow_merge_if_all_discussions_are_resolved printing_merge_request_link_enabled
      namespace group statistics repository merge_requests merge_request issues
      issue milestones pipelines removeSourceBranchAfterMerge sentryDetailedError snippets
      grafanaIntegration autocloseReferencedIssues suggestion_commit_message environments
      environment boards jira_import_status jira_imports services releases release
      alert_management_alerts alert_management_alert alert_management_alert_status_counts
      container_expiration_policy service_desk_enabled service_desk_address
      issue_status_counts terraform_states alert_management_integrations
      container_repositories container_repositories_count
      pipeline_analytics squash_read_only sast_ci_configuration
      ci_template
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  describe 'container_registry_enabled' do
    let_it_be(:project, reload: true) { create(:project, :public) }
    let_it_be(:user) { create(:user) }

    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            containerRegistryEnabled
          }
        }
      )
    end

    subject { GitlabSchema.execute(query, context: { current_user: user }).as_json }

    context 'with `enabled` visibility' do
      before do
        project.project_feature.update_column(:container_registry_access_level, ProjectFeature::ENABLED)
      end

      context 'with non member user' do
        it 'returns true' do
          expect(subject.dig('data', 'project', 'containerRegistryEnabled')).to eq(true)
        end
      end
    end

    context 'with `private` visibility' do
      before do
        project.project_feature.update_column(:container_registry_access_level, ProjectFeature::PRIVATE)
      end

      context 'with reporter user' do
        before do
          project.add_reporter(user)
        end

        it 'returns true' do
          expect(subject.dig('data', 'project', 'containerRegistryEnabled')).to eq(true)
        end
      end

      context 'with guest user' do
        before do
          project.add_guest(user)
        end

        it 'returns false' do
          expect(subject.dig('data', 'project', 'containerRegistryEnabled')).to eq(false)
        end
      end
    end
  end

  describe 'sast_ci_configuration' do
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user) }

    before do
      stub_licensed_features(security_dashboard: true)
      project.add_developer(user)
      allow(project.repository).to receive(:blob_data_at).and_return(gitlab_ci_yml_content)
    end

    include_context 'read ci configuration for sast enabled project'

    let(:query) do
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
                      size
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
                      size
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

    it "returns the project's sast configuration for global variables" do
      secure_analyzers = subject.dig('data', 'project', 'sastCiConfiguration', 'global', 'nodes').first
      expect(secure_analyzers['type']).to eq('string')
      expect(secure_analyzers['field']).to eq('SECURE_ANALYZERS_PREFIX')
      expect(secure_analyzers['label']).to eq('Image prefix')
      expect(secure_analyzers['defaultValue']).to eq(secure_analyzers_prefix)
      expect(secure_analyzers['value']).to eq(secure_analyzers_prefix)
      expect(secure_analyzers['size']).to eq('LARGE')
      expect(secure_analyzers['options']).to be_nil
    end

    it "returns the project's sast configuration for pipeline variables" do
      pipeline_stage = subject.dig('data', 'project', 'sastCiConfiguration', 'pipeline', 'nodes').first
      expect(pipeline_stage['type']).to eq('string')
      expect(pipeline_stage['field']).to eq('stage')
      expect(pipeline_stage['label']).to eq('Stage')
      expect(pipeline_stage['defaultValue']).to eq('test')
      expect(pipeline_stage['value']).to eq('test')
      expect(pipeline_stage['size']).to eq('MEDIUM')
    end

    it "returns the project's sast configuration for analyzer variables" do
      analyzer = subject.dig('data', 'project', 'sastCiConfiguration', 'analyzers', 'nodes').first
      expect(analyzer['name']).to eq('bandit')
      expect(analyzer['label']).to eq('Bandit')
      expect(analyzer['enabled']).to eq(true)
    end

    context "with guest user" do
      before do
        project.add_guest(user)
      end

      context 'when project is private' do
        let(:project) { create(:project, :private, :repository) }

        it "returns no configuration" do
          secure_analyzers_prefix = subject.dig('data', 'project', 'sastCiConfiguration')
          expect(secure_analyzers_prefix).to be_nil
        end
      end

      context 'when project is public' do
        let(:project) { create(:project, :public, :repository) }

        context 'when repository is accessible by everyone' do
          it "returns the project's sast configuration for global variables" do
            secure_analyzers_prefix = subject.dig('data', 'project', 'sastCiConfiguration', 'global', 'nodes').first

            expect(secure_analyzers_prefix['type']).to eq('string')
            expect(secure_analyzers_prefix['field']).to eq('SECURE_ANALYZERS_PREFIX')
          end
        end
      end
    end

    context "with non-member user" do
      before do
        project.team.truncate
      end

      context 'when project is private' do
        let(:project) { create(:project, :private, :repository) }

        it "returns no configuration" do
          secure_analyzers_prefix = subject.dig('data', 'project', 'sastCiConfiguration')
          expect(secure_analyzers_prefix).to be_nil
        end
      end

      context 'when project is public' do
        let(:project) { create(:project, :public, :repository) }

        context 'when repository is accessible by everyone' do
          it "returns the project's sast configuration for global variables" do
            secure_analyzers_prefix = subject.dig('data', 'project', 'sastCiConfiguration', 'global', 'nodes').first
            expect(secure_analyzers_prefix['type']).to eq('string')
            expect(secure_analyzers_prefix['field']).to eq('SECURE_ANALYZERS_PREFIX')
          end
        end

        context 'when repository is accessible only by team members' do
          it "returns no configuration" do
            project.project_feature.update!(
              merge_requests_access_level: ProjectFeature::DISABLED,
              builds_access_level: ProjectFeature::DISABLED,
              repository_access_level: ProjectFeature::PRIVATE
            )

            secure_analyzers_prefix = subject.dig('data', 'project', 'sastCiConfiguration')
            expect(secure_analyzers_prefix).to be_nil
          end
        end
      end
    end
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
    it { is_expected.to have_graphql_resolver(Resolvers::ProjectMergeRequestsResolver) }

    it do
      is_expected.to have_graphql_arguments(:iids,
                                            :source_branches,
                                            :target_branches,
                                            :state,
                                            :labels,
                                            :before,
                                            :after,
                                            :first,
                                            :last,
                                            :merged_after,
                                            :merged_before,
                                            :author_username,
                                            :assignee_username,
                                            :reviewer_username,
                                            :milestone_title,
                                            :not,
                                            :sort
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

  describe 'environment field' do
    subject { described_class.fields['environment'] }

    it { is_expected.to have_graphql_type(Types::EnvironmentType) }
    it { is_expected.to have_graphql_resolver(Resolvers::EnvironmentsResolver.single) }
  end

  describe 'members field' do
    subject { described_class.fields['projectMembers'] }

    it { is_expected.to have_graphql_type(Types::MemberInterface.connection_type) }
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

  describe 'terraform state field' do
    subject { described_class.fields['terraformState'] }

    it { is_expected.to have_graphql_type(Types::Terraform::StateType) }
    it { is_expected.to have_graphql_resolver(Resolvers::Terraform::StatesResolver.single) }
  end

  describe 'terraform states field' do
    subject { described_class.fields['terraformStates'] }

    it { is_expected.to have_graphql_type(Types::Terraform::StateType.connection_type) }
    it { is_expected.to have_graphql_resolver(Resolvers::Terraform::StatesResolver) }
  end

  it_behaves_like 'a GraphQL type with labels' do
    let(:labels_resolver_arguments) { [:search_term, :includeAncestorGroups] }
  end

  describe 'jira_imports' do
    subject { resolve_field(:jira_imports, project) }

    let_it_be(:project) { create(:project, :public) }

    context 'when project has Jira imports' do
      let_it_be(:jira_import1) do
        create(:jira_import_state, :finished, project: project, jira_project_key: 'AA', created_at: 2.days.ago)
      end

      let_it_be(:jira_import2) do
        create(:jira_import_state, :finished, project: project, jira_project_key: 'BB', created_at: 5.days.ago)
      end

      it 'retrieves the imports' do
        expect(subject).to contain_exactly(jira_import1, jira_import2)
      end
    end

    context 'when project does not have Jira imports' do
      it 'returns an empty result' do
        expect(subject).to be_empty
      end
    end
  end

  describe 'pipeline_analytics field' do
    subject { described_class.fields['pipelineAnalytics'] }

    it { is_expected.to have_graphql_type(Types::Ci::AnalyticsType) }
    it { is_expected.to have_graphql_resolver(Resolvers::ProjectPipelineStatisticsResolver) }
  end

  describe 'jobs field' do
    subject { described_class.fields['jobs'] }

    it { is_expected.to have_graphql_type(Types::Ci::JobType.connection_type) }
    it { is_expected.to have_graphql_arguments(:statuses) }
  end

  describe 'ci_template field' do
    subject { described_class.fields['ciTemplate'] }

    it { is_expected.to have_graphql_type(Types::Ci::TemplateType) }
    it { is_expected.to have_graphql_arguments(:name) }
  end

  describe 'ci_job_token_scope field' do
    subject { described_class.fields['ciJobTokenScope'] }

    it { is_expected.to have_graphql_type(Types::Ci::JobTokenScopeType) }
    it { is_expected.to have_graphql_resolver(Resolvers::Ci::JobTokenScopeResolver) }
  end
end
