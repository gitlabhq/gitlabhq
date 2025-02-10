# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Project'], feature_category: :groups_and_projects do
  include GraphqlHelpers
  include ProjectForksHelper
  using RSpec::Parameterized::TableSyntax

  specify { expect(described_class).to expose_permissions_using(Types::PermissionTypes::Project) }

  specify { expect(described_class.graphql_name).to eq('Project') }

  specify { expect(described_class).to require_graphql_authorizations(:read_project) }

  specify { expect(described_class.interfaces).to include(Types::TodoableInterface) }

  it 'has the expected fields' do
    expected_fields = %w[
      user_permissions id full_path path name_with_namespace
      name description description_html tag_list topics ssh_url_to_repo
      http_url_to_repo web_url star_count forks_count
      created_at updated_at last_activity_at archived visibility
      container_registry_enabled shared_runners_enabled
      lfs_enabled merge_requests_ff_only_enabled avatar_url
      issues_enabled merge_requests_enabled wiki_enabled
      forking_access_level issues_access_level merge_requests_access_level
      snippets_enabled jobs_enabled public_jobs open_issues_count open_merge_requests_count import_status
      only_allow_merge_if_pipeline_succeeds request_access_enabled
      only_allow_merge_if_all_discussions_are_resolved printing_merge_request_link_enabled
      namespace group statistics statistics_details_paths repository merge_requests merge_request issues
      issue milestones pipelines removeSourceBranchAfterMerge pipeline_counts sentryDetailedError snippets
      grafanaIntegration autocloseReferencedIssues suggestion_commit_message environments
      environment boards jira_import_status jira_imports services releases release
      alert_management_alerts alert_management_alert alert_management_alert_status_counts
      incident_management_timeline_event incident_management_timeline_events
      container_expiration_policy service_desk_enabled service_desk_address
      issue_status_counts terraform_states alert_management_integrations
      container_protection_repository_rules container_repositories container_repositories_count max_access_level
      pipeline_analytics squash_read_only sast_ci_configuration
      cluster_agent cluster_agents agent_configurations ci_access_authorized_agents user_access_authorized_agents
      ci_template timelogs merge_commit_template squash_commit_template work_item_types
      recent_issue_boards ci_config_path_or_default packages_cleanup_policy ci_variables
      timelog_categories fork_targets branch_rules ci_config_variables pipeline_schedules languages
      incident_management_timeline_event_tags visible_forks inherited_ci_variables autocomplete_users
      ci_cd_settings detailed_import_status value_streams ml_models
      allows_multiple_merge_request_assignees allows_multiple_merge_request_reviewers is_forked
      protectable_branches available_deploy_keys explore_catalog_path
      container_protection_tag_rules allowed_custom_statuses
      pages_force_https pages_use_unique_domain ci_pipeline_creation_request
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  describe 'count' do
    let_it_be(:user) { create(:user) }

    let(:query) do
      %(
        query {
          projects {
              count
              edges {
                node {
                  id
              }
            }
          }
        }
      )
    end

    subject { GitlabSchema.execute(query, context: { current_user: user }).as_json }

    it 'returns valid projects count' do
      create(:project, namespace: user.namespace)
      create(:project, namespace: user.namespace)

      expect(subject.dig('data', 'projects', 'count')).to eq(2)
    end
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
      expect(secure_analyzers['defaultValue']).to eq('$CI_TEMPLATE_REGISTRY_HOST/security-products')
      expect(secure_analyzers['value']).to eq('$CI_TEMPLATE_REGISTRY_HOST/security-products')
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
      expect(analyzer['name']).to eq('brakeman')
      expect(analyzer['label']).to eq('Brakeman')
      expect(analyzer['enabled']).to eq(true)
    end

    context 'with guest user' do
      before do
        project.add_guest(user)
      end

      context 'when project is private' do
        let(:project) { create(:project, :private, :repository) }

        it 'returns no configuration' do
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

    context 'with non-member user', :sidekiq_inline do
      before do
        project.team.truncate
      end

      context 'when project is private' do
        let(:project) { create(:project, :private, :repository) }

        it 'returns no configuration' do
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
          it 'returns no configuration' do
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

    context 'with empty repository' do
      let_it_be(:project) { create(:project_empty_repo) }

      it 'raises an error' do
        expect(subject['errors'][0]['message']).to eq(
          'You must <a target="_blank" rel="noopener noreferrer" ' \
            'href="http://localhost/help/user/project/repository/_index.md#' \
            'add-files-to-a-repository">add at least one file to the ' \
            'repository</a> before using Security features.'
        )
      end
    end
  end

  describe 'issue field' do
    subject { described_class.fields['issue'] }

    it { is_expected.to have_graphql_type(Types::IssueType) }
    it { is_expected.to have_graphql_resolver(Resolvers::ProjectIssuesResolver.single) }
  end

  describe 'issues field' do
    subject { described_class.fields['issues'] }

    it { is_expected.to have_graphql_type(Types::IssueType.connection_type) }
    it { is_expected.to have_graphql_resolver(Resolvers::ProjectIssuesResolver) }
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
      is_expected.to include_graphql_arguments(
        :iids,
        :source_branches,
        :target_branches,
        :state,
        :draft,
        :approved,
        :labels,
        :label_name,
        :before,
        :after,
        :first,
        :last,
        :merged_after,
        :merged_before,
        :created_after,
        :created_before,
        :deployed_after,
        :deployed_before,
        :deployment_id,
        :updated_after,
        :updated_before,
        :author_username,
        :approved_by,
        :my_reaction_emoji,
        :merged_by,
        :release_tag,
        :assignee_username,
        :assignee_wildcard_id,
        :reviewer_username,
        :reviewer_wildcard_id,
        :review_state,
        :review_states,
        :milestone_title,
        :milestone_wildcard_id,
        :not,
        :sort,
        :subscribed
      )
    end
  end

  describe 'pipelineCounts field' do
    subject { described_class.fields['pipelineCounts'] }

    it { is_expected.to have_graphql_type(Types::Ci::PipelineCountsType) }
    it { is_expected.to have_graphql_resolver(Resolvers::Ci::ProjectPipelineCountsResolver) }
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

  describe 'container tags expiration policy field' do
    subject { described_class.fields['containerTagsExpirationPolicy'] }

    it { is_expected.to have_graphql_type(Types::ContainerRegistry::ContainerTagsExpirationPolicyType) }
    it { expect(subject.instance_variable_get(:@authorize)).to include(:read_container_image) }
  end

  describe 'container expiration policy field' do
    subject { described_class.fields['containerExpirationPolicy'] }

    it { is_expected.to have_graphql_type(Types::ContainerExpirationPolicyType) }
  end

  describe 'container protection repository rules' do
    subject { described_class.fields['containerProtectionRepositoryRules'] }

    it { is_expected.to have_graphql_type(Types::ContainerRegistry::Protection::RuleType.connection_type) }
    it { is_expected.to have_graphql_resolver(Resolvers::ProjectContainerRegistryProtectionRulesResolver) }
  end

  describe 'packages cleanup policy field' do
    subject { described_class.fields['packagesCleanupPolicy'] }

    it { is_expected.to have_graphql_type(Types::Packages::Cleanup::PolicyType) }
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

  describe 'timelogs field' do
    subject { described_class.fields['timelogs'] }

    it 'finds timelogs for project' do
      is_expected.to have_graphql_resolver(Resolvers::TimelogResolver)
      is_expected.to have_graphql_type(Types::TimelogType.connection_type)
    end
  end

  it_behaves_like 'a GraphQL type with labels' do
    let(:labels_resolver_arguments) { [:search_term, :includeAncestorGroups, :searchIn, :title] }
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
    it { is_expected.to have_graphql_resolver(Resolvers::Ci::ProjectPipelineAnalyticsResolver) }
  end

  describe 'jobs field' do
    subject { described_class.fields['jobs'] }

    it { is_expected.to have_graphql_type(Types::Ci::JobType.connection_type) }

    it do
      is_expected.to have_graphql_arguments(:statuses, :with_artifacts, :name, :sources,
        :after, :before, :first, :last)
    end
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

  describe 'incident_management_timeline_event_tags field' do
    subject { described_class.fields['incidentManagementTimelineEventTags'] }

    it { is_expected.to have_graphql_type(Types::IncidentManagement::TimelineEventTagType) }
  end

  describe 'mlModels field' do
    subject { described_class.fields['mlModels'] }

    it { is_expected.to have_graphql_type(Types::Ml::ModelType.connection_type) }
    it { is_expected.to have_graphql_resolver(Resolvers::Ml::FindModelsResolver) }
  end

  describe 'agent_configurations' do
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user) }
    let_it_be(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            agentConfigurations {
              nodes {
                agentName
              }
            }
          }
        }
      )
    end

    let(:agent_name) { 'example-agent-name' }
    let(:kas_client) { instance_double(Gitlab::Kas::Client, list_agent_config_files: [double(agent_name: agent_name)]) }

    subject { GitlabSchema.execute(query, context: { current_user: user }).as_json }

    before do
      project.add_maintainer(user)
      allow(Gitlab::Kas::Client).to receive(:new).and_return(kas_client)
    end

    it 'returns configured agents' do
      agents = subject.dig('data', 'project', 'agentConfigurations', 'nodes')

      expect(agents.count).to eq(1)
      expect(agents.first['agentName']).to eq(agent_name)
    end
  end

  describe 'cluster_agents' do
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user) }
    let_it_be(:cluster_agent) { create(:cluster_agent, project: project, name: 'agent-name') }
    let_it_be(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            clusterAgents {
              count
              nodes {
                id
                name
                createdAt
                updatedAt

                project {
                  id
                }
              }
            }
          }
        }
      )
    end

    subject { GitlabSchema.execute(query, context: { current_user: user }).as_json }

    before do
      project.add_maintainer(user)
    end

    it 'returns associated cluster agents' do
      agents = subject.dig('data', 'project', 'clusterAgents', 'nodes')

      expect(agents.count).to be(1)
      expect(agents.first['id']).to eq(cluster_agent.to_global_id.to_s)
      expect(agents.first['name']).to eq('agent-name')
      expect(agents.first['createdAt']).to be_present
      expect(agents.first['updatedAt']).to be_present
      expect(agents.first['project']['id']).to eq(project.to_global_id.to_s)
    end

    it 'returns count of cluster agents' do
      count = subject.dig('data', 'project', 'clusterAgents', 'count')

      expect(count).to be(project.cluster_agents.size)
    end
  end

  describe 'cluster_agent' do
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user) }
    let_it_be(:cluster_agent) { create(:cluster_agent, project: project, name: 'agent-name') }
    let_it_be(:agent_token) { create(:cluster_agent_token, agent: cluster_agent) }
    let_it_be(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            clusterAgent(name: "#{cluster_agent.name}") {
              id

              tokens {
                count
                nodes {
                  id
                }
              }
            }
          }
        }
      )
    end

    subject { GitlabSchema.execute(query, context: { current_user: user }).as_json }

    before do
      project.add_maintainer(user)
    end

    it 'returns associated cluster agents' do
      agent = subject.dig('data', 'project', 'clusterAgent')
      tokens = agent.dig('tokens', 'nodes')

      expect(agent['id']).to eq(cluster_agent.to_global_id.to_s)

      expect(tokens.count).to be(1)
      expect(tokens.first['id']).to eq(agent_token.to_global_id.to_s)
    end

    it 'returns count of agent tokens' do
      agent = subject.dig('data', 'project', 'clusterAgent')
      count = agent.dig('tokens', 'count')

      expect(cluster_agent.agent_tokens.size).to be(count)
    end
  end

  describe 'service_desk_address' do
    let(:user) { create(:user) }
    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            id
            serviceDeskAddress
          }
        }
      )
    end

    subject { GitlabSchema.execute(query, context: { current_user: user }).as_json }

    before do
      allow(::Gitlab::Email::ServiceDeskEmail).to receive(:enabled?) { true }
      allow(::Gitlab::Email::ServiceDeskEmail).to receive(:address_for_key) { 'address-suffix@example.com' }
    end

    context 'when a user can admin issues' do
      let(:project) { create(:project, :public, :service_desk_enabled) }

      before do
        project.add_reporter(user)
      end

      it 'is present' do
        expect(subject.dig('data', 'project', 'serviceDeskAddress')).to be_present
      end
    end

    context 'when a user can not admin issues' do
      let(:project) { create(:project, :public, :service_desk_disabled) }

      it 'is empty' do
        expect(subject.dig('data', 'project', 'serviceDeskAddress')).to be_blank
      end
    end
  end

  describe 'project features access level' do
    let_it_be(:project) { create(:project, :public) }

    where(project_feature: %w[forkingAccessLevel issuesAccessLevel mergeRequestsAccessLevel])

    with_them do
      let(:query) do
        %(
        query {
          project(fullPath: "#{project.full_path}") {
            #{project_feature} {
              integerValue
              stringValue
            }
          }
        }
      )
      end

      subject { GitlabSchema.execute(query).as_json.dig('data', 'project', project_feature) }

      it { is_expected.to eq({ "integerValue" => ProjectFeature::ENABLED, "stringValue" => "ENABLED" }) }
    end
  end

  describe 'open_merge_requests_count' do
    let_it_be(:project, reload: true) { create(:project, :public) }
    let_it_be(:open_merge_request) { create(:merge_request, source_project: project) }
    let_it_be(:closed_merge_request) { create(:merge_request, :closed, source_project: project) }

    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            openMergeRequestsCount
          }
        }
      )
    end

    subject(:open_merge_requests_count) do
      GitlabSchema.execute(query).as_json.dig('data', 'project', 'openMergeRequestsCount')
    end

    context 'when the user can access merge requests' do
      it { is_expected.to eq(1) }
    end

    context 'when the user cannot access merge requests' do
      before do
        project.project_feature.update!(merge_requests_access_level: ProjectFeature::PRIVATE)
      end

      it { is_expected.to be_nil }
    end
  end

  describe 'is_forked' do
    let_it_be(:user) { create(:user) }
    let_it_be(:unforked_project) { create(:project, :public) }
    let!(:forked_project) { fork_project(unforked_project) }
    let(:project) { nil }

    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            isForked
          }
        }
      )
    end

    let(:response) { GitlabSchema.execute(query).as_json }

    subject(:is_forked) { response.dig('data', 'project', 'isForked') }

    context 'when project has a fork network' do
      context 'when fork is itself' do
        let(:project) { unforked_project }

        it { is_expected.to be false }
      end

      context 'when fork is not itself' do
        let(:project) { forked_project }

        it { is_expected.to be true }

        it 'avoids N+1 queries' do
          query_count = ActiveRecord::QueryRecorder.new { response }

          expect(query_count).not_to exceed_query_limit(8)
        end
      end
    end

    context 'when project does not have a fork network' do
      let(:project) { unforked_project }

      before do
        allow(project).to receive(:fork_network).and_return(nil)
      end

      it { is_expected.to be false }
    end
  end

  describe 'branch_rules' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project, reload: true) { create(:project, :public) }
    let_it_be(:name) { 'feat/*' }
    let_it_be(:protected_branch) do
      create(:protected_branch, project: project, name: name)
    end

    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            branchRules {
              nodes {
                name
              }
            }
          }
        }
      )
    end

    let(:branch_rules_data) do
      subject.dig('data', 'project', 'branchRules', 'nodes')
    end

    subject { GitlabSchema.execute(query, context: { current_user: user }).as_json }

    context 'when a user can read protected branches' do
      before do
        project.add_maintainer(user)
      end

      it 'is present and correct' do
        expect(branch_rules_data.count).to eq(2)
        expect(branch_rules_data.first['name']).to eq('All branches')
        expect(branch_rules_data.last['name']).to eq(name)
      end
    end

    context 'when a user cannot read protected branches' do
      before do
        project.add_guest(user)
      end

      it 'is empty' do
        expect(branch_rules_data.count).to eq(0)
      end
    end
  end

  describe 'timeline_event_tags' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) do
      create(
        :project,
        :private,
        :repository,
        creator_id: user.id,
        namespace: user.namespace
      )
    end

    let_it_be(:tag1) do
      create(
        :incident_management_timeline_event_tag,
        project: project,
        name: 'Tag 1'
      )
    end

    let_it_be(:tag2) do
      create(
        :incident_management_timeline_event_tag,
        project: project,
        name: 'Tag 2'
      )
    end

    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            incidentManagementTimelineEventTags {
              name
              id
            }
          }
        }
      )
    end

    let(:tags) do
      subject.dig('data', 'project', 'incidentManagementTimelineEventTags')
    end

    subject { GitlabSchema.execute(query, context: { current_user: user }).as_json }

    context 'when user has permissions to read project' do
      before do
        project.add_developer(user)
      end

      it 'contains timeline event tags' do
        expect(tags.count).to eq(2)
        expect(tags.first['name']).to eq(tag1.name)
        expect(tags.last['name']).to eq(tag2.name)
      end
    end
  end

  describe 'languages' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) do
      create(
        :project,
        :private,
        :repository,
        creator_id: user.id,
        namespace: user.namespace
      )
    end

    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            languages {
              name
              share
              color
            }
          }
        }
      )
    end

    let(:mock_languages) { [] }

    before do
      allow_next_instance_of(::Projects::RepositoryLanguagesService) do |service|
        allow(service).to receive(:execute).and_return(mock_languages)
      end
    end

    subject { GitlabSchema.execute(query, context: { current_user: user }).as_json }

    let(:languages) { subject.dig('data', 'project', 'languages') }

    context "when the languages haven't been detected yet" do
      it 'returns an empty array' do
        expect(languages).to eq([])
      end
    end

    context 'when the languages were detected before' do
      let(:mock_languages) do
        [{ share: 66.69, name: "Ruby", color: "#701516" },
         { share: 22.98, name: "JavaScript", color: "#f1e05a" },
         { share: 7.91, name: "HTML", color: "#e34c26" },
         { share: 2.42, name: "CoffeeScript", color: "#244776" }]
      end

      it 'returns the repository languages' do
        expect(languages).to eq(mock_languages.map(&:stringify_keys))
      end
    end
  end

  describe 'visible_forks' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:fork_reporter) { fork_project(project, nil, { repository: true }) }
    let_it_be(:fork_developer) { fork_project(project, nil, { repository: true }) }
    let_it_be(:fork_group_developer) { fork_project(project, nil, { repository: true }) }
    let_it_be(:fork_public) { fork_project(project, nil, { repository: true }) }
    let_it_be(:fork_private) { fork_project(project, nil, { repository: true }) }

    let(:minimum_access_level) { '' }
    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            visibleForks#{minimum_access_level} {
              nodes {
                fullPath
              }
            }
          }
        }
      )
    end

    let(:forks) do
      subject.dig('data', 'project', 'visibleForks', 'nodes')
    end

    subject { GitlabSchema.execute(query, context: { current_user: user }).as_json }

    before_all do
      fork_reporter.add_reporter(user)
      fork_developer.add_developer(user)
      fork_group_developer.group.add_developer(user)
      fork_private.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
    end

    it 'contains all forks' do
      expect(forks.count).to eq(4)
    end

    context 'with minimum_access_level DEVELOPER' do
      let(:minimum_access_level) { '(minimumAccessLevel: DEVELOPER)' }

      it 'contains forks with developer access' do
        expect(forks).to contain_exactly(
          a_hash_including('fullPath' => fork_developer.full_path),
          a_hash_including('fullPath' => fork_group_developer.full_path)
        )
      end

      context 'when current user is not set' do
        let(:user) { nil }

        it 'does not return any forks' do
          expect(forks.count).to eq(0)
        end
      end
    end
  end

  describe 'detailed_import_status' do
    let_it_be_with_reload(:project) { create(:project, :with_import_url) }

    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            detailedImportStatus {
              status
              url
              lastError
            }
          }
        }
      )
    end

    subject { GitlabSchema.execute(query, context: { current_user: current_user }).as_json }

    let(:detailed_import_status) do
      subject.dig('data', 'project', 'detailedImportStatus')
    end

    context 'when project is not imported' do
      let(:current_user) { create(:user) }

      before do
        project.add_developer(current_user)
        project.import_state.destroy!
      end

      it 'returns nil' do
        expect(detailed_import_status).to be_nil
      end
    end

    context 'when current_user is not set' do
      let(:current_user) { nil }

      it 'returns nil' do
        expect(detailed_import_status).to be_nil
      end
    end

    context 'when current_user has no permission' do
      let(:current_user) { create(:user) }

      it 'returns nil' do
        expect(detailed_import_status).to be_nil
      end
    end

    context 'when current_user has limited permission' do
      let(:current_user) { create(:user) }

      before do
        project.add_developer(current_user)
        project.import_state.last_error = 'Some error'
        project.import_state.save!
      end

      it 'returns detailed information' do
        expect(detailed_import_status).to include(
          'status' => project.import_state.status,
          'url' => project.safe_import_url,
          'lastError' => nil
        )
      end
    end

    context 'when current_user has permission' do
      let(:current_user) { create(:user) }

      before do
        project.add_maintainer(current_user)
        project.import_state.last_error = 'Some error'
        project.import_state.save!
      end

      it 'returns detailed information' do
        expect(detailed_import_status).to include(
          'status' => project.import_state.status,
          'url' => project.safe_import_url,
          'lastError' => 'Some error'
        )
      end
    end
  end

  describe 'protectable_branches' do
    subject { GitlabSchema.execute(query, context: { current_user: current_user }).as_json }

    let_it_be(:current_user) { create(:user) }
    let_it_be(:project) { create(:project, :empty_repo) }

    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            id
            protectableBranches
          }
        }
      )
    end

    let(:protectable_branches) do
      subject.dig('data', 'project', 'protectableBranches')
    end

    before_all do
      project.add_maintainer(current_user)
    end

    describe 'an empty repository' do
      let(:project) { create(:project, :empty_repo, maintainers: current_user) }

      it 'returns an empty array' do
        expect(protectable_branches).to be_empty
      end
    end

    describe 'a repository with branches' do
      let(:branch_names) { %w[master feat/dropdown] }

      before_all do
        project.add_maintainer(current_user)
        project.repository.create_file(
          current_user, 'test.txt', 'content', message: 'init', branch_name: 'master'
        )
        project.repository.create_branch('feat/dropdown', 'master')
      end

      context 'and no protections' do
        it 'returns all the branch names' do
          expect(protectable_branches).to match_array(branch_names)
        end
      end

      context 'and all branches are protected with specific rules' do
        before do
          branch_names.each do |name|
            create(:protected_branch, project: project, name: name)
          end
        end

        it 'returns an empty array' do
          expect(protectable_branches).to be_empty
        end
      end

      context 'and all branches are protected with a wildcard rule' do
        before do
          create(:protected_branch, name: '*')
        end

        it 'returns all the branch names' do
          expect(protectable_branches).to match_array(branch_names)
        end
      end

      context 'without read_code permissions' do
        before do
          project.add_guest(current_user)
        end

        it 'returns an empty array' do
          expect(protectable_branches).to be_nil
        end
      end

      context 'with read_code permissions' do
        before do
          project.add_member(current_user, Gitlab::Access::REPORTER)
        end

        it 'returns all the branch names' do
          expect(protectable_branches).to match_array(branch_names)
        end
      end
    end
  end

  describe 'available_deploy_keys' do
    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            availableDeployKeys{
              nodes{
                id
                title
                user {
                  username
                }
              }
            }
          }
        }
      )
    end

    subject { GitlabSchema.execute(query, context: { current_user: current_user }).as_json }

    let_it_be(:project) { create :project }
    let_it_be(:deploy_key) { create(:deploy_keys_project, :write_access, project: project).deploy_key }
    let_it_be(:maintainer) { create(:user) }
    let(:available_deploy_keys) { subject.dig('data', 'project', 'availableDeployKeys', 'nodes') }

    context 'when there are deploy keys' do
      before_all do
        project.add_maintainer(maintainer)
      end

      context 'and the current user has access' do
        let(:current_user) { maintainer }

        it 'returns the deploy keys' do
          expect(available_deploy_keys[0]).to include({
            'id' => deploy_key.to_global_id.to_s,
            'title' => deploy_key.title,
            'user' => {
              'username' => deploy_key.user.username
            }
          })
        end
      end

      context 'and the current user does not have access' do
        let(:current_user) { create(:user) }

        it 'does not return any deploy keys' do
          expect(available_deploy_keys).to be_nil
        end
      end
    end
  end

  describe 'organization_edit_path' do
    let_it_be(:user) { create(:user) }
    let_it_be(:organization) { create(:organization) }
    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            organizationEditPath
          }
        }
      )
    end

    let(:response) { GitlabSchema.execute(query, context: { current_user: user }).as_json }

    subject(:organization_edit_path) { response.dig('data', 'project', 'organizationEditPath') }

    context 'when project has an organization associated with it' do
      let_it_be(:project) { create(:project, :public, organization: organization) }

      it 'returns edit path scoped to organization' do
        expect(organization_edit_path).to eq(
          "/-/organizations/#{organization.path}/projects/#{project.path_with_namespace}/edit"
        )
      end
    end
  end

  describe 'explore_catalog_path' do
    let_it_be(:user) { create(:user) }
    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            exploreCatalogPath
          }
        }
      )
    end

    let(:response) { GitlabSchema.execute(query, context: { current_user: user }).as_json }

    subject(:explore_catalog_path) { response.dig('data', 'project', 'exploreCatalogPath') }

    context 'when project is not a catalog resource' do
      let_it_be(:project) { create(:project, :public) }

      it 'returns nil for explore_catalog_path' do
        expect(explore_catalog_path).to be_nil
      end
    end

    context 'when project is a catalog resource' do
      let_it_be(:project) { create(:project, :public, :catalog_resource_with_components, create_tag: '1.0.0') }
      let_it_be(:catalog_resource) { create(:ci_catalog_resource, project: project) }

      it 'returns correct path for explore_catalog_path' do
        expect(explore_catalog_path).to eq("/explore/catalog/#{project.path_with_namespace}")
      end
    end
  end

  describe 'pages_force_https' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:project) { create(:project, :repository) }
    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            pagesForceHttps
          }
        }
      )
    end

    let(:response) { GitlabSchema.execute(query, context: { current_user: current_user }).as_json }

    subject(:result) { response.dig('data', 'project', 'pagesForceHttps') }

    before do
      project.add_maintainer(current_user)
    end

    context 'when the redirect from unsecured connections to HTTPS is disabled' do
      it 'returns "false"' do
        expect(result).to be false
      end
    end

    context 'when the redirect from unsecured connections to HTTPS is enabled' do
      it 'returns "true"' do
        allow(Gitlab.config.pages).to receive(:external_https).and_return(true)

        expect(result).to be true
      end
    end
  end

  describe 'pages_use_unique_domain' do
    let_it_be(:current_user) { create(:user) }
    let(:project) { create(:project, :repository, project_setting: project_settings) }
    let(:query) do
      %(
        query {
          project(fullPath: "#{project.full_path}") {
            pagesUseUniqueDomain
          }
        }
      )
    end

    let(:response) { GitlabSchema.execute(query, context: { current_user: current_user }).as_json }

    subject(:result) { response.dig('data', 'project', 'pagesUseUniqueDomain') }

    before do
      project.add_maintainer(current_user)
    end

    context 'when the project pages site uses a unique subdomain' do
      let(:project_settings) do
        create(:project_setting, pages_unique_domain_enabled: true, pages_unique_domain: "test-unique-domain")
      end

      it 'returns "true"' do
        expect(result).to be true
      end
    end

    context 'when the project pages site does not use a unique subdomain' do
      let(:project_settings) { create(:project_setting, pages_unique_domain_enabled: false) }

      it 'returns "false"' do
        expect(result).to be false
      end
    end
  end
end
