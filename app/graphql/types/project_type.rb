# frozen_string_literal: true

module Types
  class ProjectType < BaseObject
    graphql_name 'Project'

    connection_type_class Types::CountableConnectionType

    authorize :read_project

    expose_permissions Types::PermissionTypes::Project

    implements Types::TodoableInterface

    field :id, GraphQL::Types::ID,
      null: false,
      description: 'ID of the project.'

    field :ci_config_path_or_default, GraphQL::Types::String,
      null: false,
      description: 'Path of the CI configuration file.'

    field :ci_config_variables, [Types::Ci::ConfigVariableType],
      null: true,
      calls_gitaly: true,
      authorize: :create_pipeline,
      experiment: { milestone: '15.3' },
      description: 'CI/CD config variable.' do
      argument :ref, GraphQL::Types::String,
        required: true,
        description: 'Ref.'
    end

    field :ci_pipeline_creation_request, Types::Ci::PipelineCreation::RequestType,
      authorize: :create_pipeline,
      description: 'Get information about an asynchronous pipeline creation request.',
      experiment: { milestone: '17.9' } do
      argument :request_id, GraphQL::Types::String,
        required: true,
        description: 'ID of the pipeline creation request.'
    end

    field :full_path, GraphQL::Types::ID,
      null: false,
      description: 'Full path of the project.'

    field :path, GraphQL::Types::String,
      null: false,
      description: 'Path of the project.'

    field :organization_edit_path, GraphQL::Types::String,
      null: true,
      description: 'Path for editing project at the organization level.',
      experiment: { milestone: '16.11' }

    field :incident_management_timeline_event_tags, [Types::IncidentManagement::TimelineEventTagType],
      null: true,
      description: 'Timeline event tags for the project.'

    field :sast_ci_configuration, Types::CiConfiguration::Sast::Type,
      null: true,
      calls_gitaly: true,
      description: 'SAST CI configuration for the project.'

    field :name, GraphQL::Types::String,
      null: false,
      description: 'Name of the project (without namespace).'

    field :name_with_namespace, GraphQL::Types::String,
      null: false,
      description: 'Full name of the project with its namespace.'

    field :description, GraphQL::Types::String,
      null: true,
      description: 'Short description of the project.'

    field :tag_list, GraphQL::Types::String,
      null: true,
      deprecated: { reason: 'Use `topics`', milestone: '13.12' },
      description: 'List of project topics (not Git tags).',
      method: :topic_list

    field :topics, [GraphQL::Types::String],
      null: true,
      description: 'List of project topics.',
      method: :topic_list

    field :http_url_to_repo, GraphQL::Types::String,
      null: true,
      description: 'URL to connect to the project via HTTPS.'

    field :ssh_url_to_repo, GraphQL::Types::String,
      null: true,
      description: 'URL to connect to the project via SSH.'

    field :web_url, GraphQL::Types::String,
      null: true,
      description: 'Web URL of the project.'

    field :forks_count, GraphQL::Types::Int,
      null: false,
      calls_gitaly: true, # 4 times
      description: 'Number of times the project has been forked.'

    field :star_count, GraphQL::Types::Int,
      null: false,
      description: 'Number of times the project has been starred.'

    field :created_at, Types::TimeType,
      null: true,
      description: 'Timestamp of the project creation.'

    field :updated_at, Types::TimeType,
      null: true,
      description: 'Timestamp of when the project was last updated.'

    field :last_activity_at, Types::TimeType,
      null: true,
      description: 'Timestamp of the project last activity.'

    field :archived, GraphQL::Types::Boolean,
      null: true,
      description: 'Indicates the archived status of the project.'

    field :visibility, GraphQL::Types::String,
      null: true,
      description: 'Visibility of the project.'

    field :lfs_enabled, GraphQL::Types::Boolean,
      null: true,
      description: 'Indicates if the project has Large File Storage (LFS) enabled.'

    field :max_access_level, Types::AccessLevelType,
      null: false,
      description: 'The maximum access level of the current user in the project.'

    field :merge_requests_ff_only_enabled, GraphQL::Types::Boolean,
      null: true,
      description: 'Indicates if no merge commits should be created and all merges should instead be ' \
        'fast-forwarded, which means that merging is only allowed if the branch could be fast-forwarded.'

    field :shared_runners_enabled, GraphQL::Types::Boolean,
      null: true,
      description: 'Indicates if shared runners are enabled for the project.'

    field :service_desk_enabled, GraphQL::Types::Boolean,
      null: true,
      description: 'Indicates if the project has Service Desk enabled.'

    field :service_desk_address, GraphQL::Types::String,
      null: true,
      description: 'E-mail address of the Service Desk.'

    field :avatar_url, GraphQL::Types::String,
      null: true,
      calls_gitaly: true,
      description: 'URL to avatar image file of the project.'

    field :jobs_enabled, GraphQL::Types::Boolean,
      null: true,
      description: 'Indicates if CI/CD pipeline jobs are enabled for the current user.'

    field :is_catalog_resource, GraphQL::Types::Boolean,
      experiment: { milestone: '15.11' },
      null: true,
      description: 'Indicates if a project is a catalog resource.'

    field :explore_catalog_path, GraphQL::Types::String,
      experiment: { milestone: '17.6' },
      null: true,
      description: 'Path to the project catalog resource.'

    field :public_jobs, GraphQL::Types::Boolean,
      null: true,
      description: 'Indicates if there is public access to pipelines and job details of the project, ' \
        'including output logs and artifacts.',
      method: :public_builds

    field :open_issues_count, GraphQL::Types::Int,
      null: true,
      description: 'Number of open issues for the project.'

    field :open_merge_requests_count, GraphQL::Types::Int,
      null: true,
      description: 'Number of open merge requests for the project.'

    field :allow_merge_on_skipped_pipeline, GraphQL::Types::Boolean,
      null: true,
      description: 'If `only_allow_merge_if_pipeline_succeeds` is true, indicates if merge requests of ' \
        'the project can also be merged with skipped jobs.'

    field :autoclose_referenced_issues, GraphQL::Types::Boolean,
      null: true,
      description: 'Indicates if issues referenced by merge requests and commits within the default branch ' \
        'are closed automatically.'

    field :import_status, GraphQL::Types::String,
      null: true,
      description: 'Status of import background job of the project.'

    field :jira_import_status, GraphQL::Types::String,
      null: true,
      description: 'Status of Jira import background job of the project.'

    field :only_allow_merge_if_all_discussions_are_resolved, GraphQL::Types::Boolean,
      null: true,
      description: 'Indicates if merge requests of the project can only be merged ' \
        'when all the discussions are resolved.'

    field :only_allow_merge_if_pipeline_succeeds, GraphQL::Types::Boolean,
      null: true,
      description: 'Indicates if merge requests of the project can only be merged with successful jobs.'

    field :printing_merge_request_link_enabled, GraphQL::Types::Boolean,
      null: true,
      description: 'Indicates if a link to create or view a merge request should display after a push to Git ' \
        'repositories of the project from the command line.'

    field :remove_source_branch_after_merge, GraphQL::Types::Boolean,
      null: true,
      description: 'Indicates if `Delete source branch` option should be enabled by default for all ' \
        'new merge requests of the project.'

    field :request_access_enabled, GraphQL::Types::Boolean,
      null: true,
      description: 'Indicates if users can request member access to the project.'

    field :squash_read_only, GraphQL::Types::Boolean,
      null: false,
      description: 'Indicates if `squashReadOnly` is enabled.',
      method: :squash_readonly?

    field :suggestion_commit_message, GraphQL::Types::String,
      null: true,
      description: 'Commit message used to apply merge request suggestions.'

    # No, the quotes are not a typo. Used to get around circular dependencies.
    # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/27536#note_871009675
    field :group, 'Types::GroupType',
      null: true,
      description: 'Group of the project.'

    field :namespace, Types::NamespaceType,
      null: true,
      description: 'Namespace of the project.'

    field :statistics, Types::ProjectStatisticsType,
      null: true,
      description: 'Statistics of the project.'

    field :statistics_details_paths, Types::ProjectStatisticsRedirectType,
      null: true,
      description: 'Redirects for Statistics of the project.',
      calls_gitaly: true

    field :repository, Types::RepositoryType,
      null: true,
      description: 'Git repository of the project.'

    field :merge_requests,
      Types::MergeRequestType.connection_type,
      null: true,
      description: 'Merge requests of the project.',
      extras: [:lookahead],
      resolver: Resolvers::ProjectMergeRequestsResolver

    field :merge_request,
      Types::MergeRequestType,
      null: true,
      description: 'A single merge request of the project.',
      resolver: Resolvers::MergeRequestsResolver.single

    field :issues,
      Types::IssueType.connection_type,
      null: true,
      description: 'Issues of the project.',
      resolver: Resolvers::ProjectIssuesResolver

    field :work_items,
      Types::WorkItemType.connection_type,
      null: true,
      experiment: { milestone: '15.1' },
      description: 'Work items of the project.',
      extras: [:lookahead],
      resolver: Resolvers::WorkItemsResolver

    field :work_item_state_counts,
      Types::WorkItemStateCountsType,
      null: true,
      experiment: { milestone: '16.7' },
      description: 'Counts of work items by state for the project.',
      resolver: Resolvers::WorkItemStateCountsResolver

    field :issue_status_counts,
      Types::IssueStatusCountsType,
      null: true,
      description: 'Counts of issues by status for the project.',
      resolver: Resolvers::IssueStatusCountsResolver

    field :milestones, Types::MilestoneType.connection_type,
      null: true,
      description: 'Milestones of the project.',
      resolver: Resolvers::ProjectMilestonesResolver

    field :project_members,
      description: 'Members of the project.',
      resolver: Resolvers::ProjectMembersResolver

    field :environments,
      Types::EnvironmentType.connection_type,
      null: true,
      description: 'Environments of the project. ' \
        'This field can only be resolved for one project in any single request.',
      resolver: Resolvers::EnvironmentsResolver do
      extension ::Gitlab::Graphql::Limit::FieldCallCount, limit: 1
    end

    field :environment,
      Types::EnvironmentType,
      null: true,
      description: 'A single environment of the project.',
      resolver: Resolvers::EnvironmentsResolver.single

    field :nested_environments,
      Types::NestedEnvironmentType.connection_type,
      null: true,
      calls_gitaly: true,
      description: 'Environments for this project with nested folders, ' \
        'can only be resolved for one project in any single request',
      resolver: Resolvers::Environments::NestedEnvironmentsResolver do
      extension ::Gitlab::Graphql::Limit::FieldCallCount, limit: 1
    end

    field :deployment,
      Types::DeploymentType,
      null: true,
      description: 'Details of the deployment of the project.',
      resolver: Resolvers::DeploymentResolver.single

    field :issue,
      Types::IssueType,
      null: true,
      description: 'A single issue of the project.',
      resolver: Resolvers::ProjectIssuesResolver.single

    field :packages,
      description: 'Packages of the project.',
      resolver: Resolvers::ProjectPackagesResolver

    field :packages_cleanup_policy,
      Types::Packages::Cleanup::PolicyType,
      null: true,
      description: 'Packages cleanup policy for the project.'

    field :packages_protection_rules,
      Types::Packages::Protection::RuleType.connection_type,
      null: true,
      description: 'Packages protection rules for the project.',
      experiment: { milestone: '16.6' },
      resolver: Resolvers::ProjectPackagesProtectionRulesResolver

    field :jobs,
      type: Types::Ci::JobType.connection_type,
      null: true,
      authorize: :read_build,
      description: 'Jobs of a project. This field can only be resolved for one project in any single request.',
      resolver: Resolvers::ProjectJobsResolver,
      connection_extension: ::Gitlab::Graphql::Extensions::ExternallyPaginatedArrayExtension

    field :job,
      type: Types::Ci::JobType,
      null: true,
      authorize: :read_build,
      description: 'One job belonging to the project, selected by ID.' do
      argument :id, Types::GlobalIDType[::CommitStatus],
        required: true,
        description: 'ID of the job.'
    end

    field :pipelines,
      null: true,
      description: 'Pipelines of the project.',
      extras: [:lookahead],
      resolver: Resolvers::Ci::ProjectPipelinesResolver

    field :pipeline_schedules,
      type: Types::Ci::PipelineScheduleType.connection_type,
      null: true,
      description: 'Pipeline schedules of the project. This field can only be resolved for one project per request.',
      resolver: Resolvers::Ci::ProjectPipelineSchedulesResolver

    field :pipeline_triggers,
      Types::Ci::PipelineTriggerType.connection_type,
      null: true,
      description: 'List of pipeline trigger tokens.',
      resolver: Resolvers::Ci::PipelineTriggersResolver,
      experiment: { milestone: '16.3' }

    field :pipeline, Types::Ci::PipelineType,
      null: true,
      description: 'Pipeline of the project. If no arguments are provided, returns the latest pipeline for the ' \
        'head commit on the default branch',
      extras: [:lookahead],
      resolver: Resolvers::Ci::ProjectPipelineResolver

    field :pipeline_counts, Types::Ci::PipelineCountsType,
      null: true,
      description: 'Pipeline counts of the project.',
      resolver: Resolvers::Ci::ProjectPipelineCountsResolver

    field :ci_variables, Types::Ci::ProjectVariableType.connection_type,
      null: true,
      description: "List of the project's CI/CD variables.",
      authorize: :admin_cicd_variables,
      resolver: Resolvers::Ci::VariablesResolver

    field :inherited_ci_variables, Types::Ci::InheritedCiVariableType.connection_type,
      null: true,
      description: "List of CI/CD variables the project inherited from its parent group and ancestors.",
      authorize: :admin_cicd_variables,
      resolver: Resolvers::Ci::InheritedVariablesResolver

    field :ci_cd_settings, Types::Ci::CiCdSettingType,
      null: true,
      description: 'CI/CD settings for the project.'

    field :sentry_detailed_error, Types::ErrorTracking::SentryDetailedErrorType,
      null: true,
      description: 'Detailed version of a Sentry error on the project.',
      resolver: Resolvers::ErrorTracking::SentryDetailedErrorResolver

    field :grafana_integration, Types::GrafanaIntegrationType,
      null: true,
      description: 'Grafana integration details for the project.',
      resolver: Resolvers::Projects::GrafanaIntegrationResolver

    field :snippets, Types::SnippetType.connection_type,
      null: true,
      description: 'Snippets of the project.',
      resolver: Resolvers::Projects::SnippetsResolver

    field :sentry_errors, Types::ErrorTracking::SentryErrorCollectionType,
      null: true,
      description: 'Paginated collection of Sentry errors on the project.',
      resolver: Resolvers::ErrorTracking::SentryErrorCollectionResolver

    field :boards, Types::BoardType.connection_type,
      null: true,
      description: 'Boards of the project.',
      max_page_size: 2000,
      resolver: Resolvers::BoardsResolver

    field :recent_issue_boards, Types::BoardType.connection_type,
      null: true,
      description: 'List of recently visited boards of the project. Maximum size is 4.',
      resolver: Resolvers::RecentBoardsResolver

    field :board, Types::BoardType,
      null: true,
      description: 'A single board of the project.',
      resolver: Resolvers::BoardResolver

    field :jira_imports, Types::JiraImportType.connection_type,
      null: true,
      description: 'Jira imports into the project.'

    field :services, Types::Projects::ServiceType.connection_type,
      null: true,
      deprecated: {
        reason: 'A `Project.integrations` field is proposed instead in [issue 389904](https://gitlab.com/gitlab-org/gitlab/-/issues/389904)',
        milestone: '15.9'
      },
      description: 'Project services.',
      resolver: Resolvers::Projects::ServicesResolver

    field :alert_management_alerts, Types::AlertManagement::AlertType.connection_type,
      null: true,
      description: 'Alert Management alerts of the project.',
      extras: [:lookahead],
      resolver: Resolvers::AlertManagement::AlertResolver

    field :alert_management_alert, Types::AlertManagement::AlertType,
      null: true,
      description: 'A single Alert Management alert of the project.',
      resolver: Resolvers::AlertManagement::AlertResolver.single

    field :alert_management_alert_status_counts, Types::AlertManagement::AlertStatusCountsType,
      null: true,
      description: 'Counts of alerts by status for the project.',
      resolver: Resolvers::AlertManagement::AlertStatusCountsResolver

    field :alert_management_integrations, Types::AlertManagement::IntegrationType.connection_type,
      null: true,
      description: 'Integrations which can receive alerts for the project.',
      resolver: Resolvers::AlertManagement::IntegrationsResolver

    field :alert_management_http_integrations, Types::AlertManagement::HttpIntegrationType.connection_type,
      null: true,
      description: 'HTTP Integrations which can receive alerts for the project.',
      resolver: Resolvers::AlertManagement::HttpIntegrationsResolver

    field :incident_management_timeline_events, Types::IncidentManagement::TimelineEventType.connection_type,
      null: true,
      description: 'Incident Management Timeline events associated with the incident.',
      extras: [:lookahead],
      resolver: Resolvers::IncidentManagement::TimelineEventsResolver

    field :incident_management_timeline_event, Types::IncidentManagement::TimelineEventType,
      null: true,
      description: 'Incident Management Timeline event associated with the incident.',
      resolver: Resolvers::IncidentManagement::TimelineEventsResolver.single

    field :releases, Types::ReleaseType.connection_type,
      null: true,
      description: 'Releases of the project.',
      resolver: Resolvers::ReleasesResolver

    field :release, Types::ReleaseType,
      null: true,
      description: 'A single release of the project.',
      resolver: Resolvers::ReleasesResolver.single,
      authorize: :read_release

    field :container_tags_expiration_policy, Types::ContainerRegistry::ContainerTagsExpirationPolicyType,
      null: true,
      description: 'Container tags expiration policy of the project.',
      method: :container_expiration_policy,
      authorize: :read_container_image

    field :container_expiration_policy, Types::ContainerExpirationPolicyType,
      null: true,
      deprecated: { reason: 'Use `container_tags_expiration_policy`', milestone: '17.5' },
      description: 'Container expiration policy of the project.'

    field :container_protection_repository_rules,
      Types::ContainerRegistry::Protection::RuleType.connection_type,
      null: true,
      description: 'Container protection rules for the project.',
      experiment: { milestone: '16.10' },
      resolver: Resolvers::ProjectContainerRegistryProtectionRulesResolver

    field :container_protection_tag_rules,
      Types::ContainerRegistry::Protection::TagRuleType.connection_type,
      null: true,
      experiment: { milestone: '17.8' },
      description: 'Container repository tag protection rules for the project. ' \
        'Returns an empty array if the `container_registry_protected_tags` feature flag is disabled.'

    field :container_repositories, Types::ContainerRegistry::ContainerRepositoryType.connection_type,
      null: true,
      description: 'Container repositories of the project.',
      resolver: Resolvers::ContainerRepositoriesResolver

    field :container_repositories_count, GraphQL::Types::Int,
      null: false,
      description: 'Number of container repositories in the project.'

    field :label, Types::LabelType,
      null: true,
      description: 'Label available on this project.' do
      argument :title, GraphQL::Types::String,
        required: true,
        description: 'Title of the label.'
    end

    field :terraform_state, Types::Terraform::StateType,
      null: true,
      description: 'Find a single Terraform state by name.',
      resolver: Resolvers::Terraform::StatesResolver.single

    field :terraform_states, Types::Terraform::StateType.connection_type,
      null: true,
      description: 'Terraform states associated with the project.',
      resolver: Resolvers::Terraform::StatesResolver

    field :pipeline_analytics, Types::Ci::AnalyticsType,
      null: true,
      description: 'Pipeline analytics.',
      resolver: Resolvers::Ci::ProjectPipelineAnalyticsResolver

    field :ci_template, Types::Ci::TemplateType,
      null: true,
      description: 'Find a single CI/CD template by name.',
      resolver: Resolvers::Ci::TemplateResolver

    field :ci_job_token_scope, Types::Ci::JobTokenScopeType,
      null: true,
      description: 'The CI Job Tokens scope of access.',
      resolver: Resolvers::Ci::JobTokenScopeResolver

    field :ci_job_token_scope_allowlist, Types::Ci::JobTokenScope::AllowlistType,
      null: true,
      experiment: { milestone: '17.6' },
      description: 'List of CI job token scopes where the project is the source.',
      resolver: Resolvers::Ci::JobTokenScopeAllowlistResolver

    field :ci_job_token_auth_logs, Types::Ci::JobTokenAuthLogType.connection_type,
      null: true,
      experiment: { milestone: '17.6' },
      description: 'The CI Job Tokens authorization logs.',
      extras: [:lookahead],
      resolver: Resolvers::Ci::JobTokenAuthLogsResolver

    field :timelogs, Types::TimelogType.connection_type,
      null: true,
      description: 'Time logged on issues and merge requests in the project.',
      extras: [:lookahead],
      complexity: 5,
      resolver: ::Resolvers::TimelogResolver

    field :agent_configurations,
      null: true,
      description: 'Agent configurations defined by the project',
      resolver: ::Resolvers::Kas::AgentConfigurationsResolver

    field :cluster_agent, ::Types::Clusters::AgentType,
      null: true,
      description: 'Find a single cluster agent by name.',
      resolver: ::Resolvers::Clusters::AgentsResolver.single

    field :cluster_agents, ::Types::Clusters::AgentType.connection_type,
      extras: [:lookahead],
      null: true,
      description: 'Cluster agents associated with the project.',
      resolver: ::Resolvers::Clusters::AgentsResolver

    field :ci_access_authorized_agents, ::Types::Clusters::Agents::Authorizations::CiAccessType.connection_type,
      null: true,
      description: 'Authorized cluster agents for the project through ci_access keyword.',
      resolver: ::Resolvers::Clusters::Agents::Authorizations::CiAccessResolver,
      authorize: :read_cluster_agent

    field :user_access_authorized_agents, ::Types::Clusters::Agents::Authorizations::UserAccessType.connection_type,
      null: true,
      description: 'Authorized cluster agents for the project through user_access keyword.',
      resolver: ::Resolvers::Clusters::Agents::Authorizations::UserAccessResolver,
      authorize: :read_cluster_agent

    field :merge_commit_template, GraphQL::Types::String,
      null: true,
      description: 'Template used to create merge commit message in merge requests.'

    field :squash_commit_template, GraphQL::Types::String,
      null: true,
      description: 'Template used to create squash commit message in merge requests.'

    field :labels, Types::LabelType.connection_type,
      null: true,
      description: 'Labels available on this project.',
      resolver: Resolvers::LabelsResolver

    field :work_item_types, Types::WorkItems::TypeType.connection_type,
      resolver: Resolvers::WorkItems::TypesResolver,
      description: 'Work item types available to the project.'

    field :timelog_categories, Types::TimeTracking::TimelogCategoryType.connection_type,
      null: true,
      description: "Timelog categories for the project.",
      experiment: { milestone: '15.3' }

    field :fork_targets, Types::NamespaceType.connection_type,
      resolver: Resolvers::Projects::ForkTargetsResolver,
      description: 'Namespaces in which the current user can fork the project into.'

    field :fork_details, Types::Projects::ForkDetailsType,
      calls_gitaly: true,
      experiment: { milestone: '15.7' },
      authorize: :read_code,
      resolver: Resolvers::Projects::ForkDetailsResolver,
      description: 'Details of the fork project compared to its upstream project.'

    field :branch_rules, Types::Projects::BranchRuleType.connection_type,
      null: true,
      description: "Branch rules configured for the project.",
      resolver: Resolvers::Projects::BranchRulesResolver

    field :languages, [Types::Projects::RepositoryLanguageType],
      null: true,
      description: "Programming languages used in the project.",
      calls_gitaly: true

    field :runners, Types::Ci::RunnerType.connection_type,
      null: true,
      resolver: ::Resolvers::Ci::ProjectRunnersResolver,
      description: "Find runners visible to the current user."

    field :data_transfer, Types::DataTransfer::ProjectDataTransferType,
      null: true, # disallow null once data_transfer_monitoring feature flag is rolled-out! https://gitlab.com/gitlab-org/gitlab/-/issues/391682
      resolver: Resolvers::DataTransfer::ProjectDataTransferResolver,
      description: 'Data transfer data point for a specific period. ' \
        'This is mocked data under a development feature flag.'

    field :visible_forks, Types::ProjectType.connection_type,
      null: true,
      experiment: { milestone: '15.10' },
      description: "Visible forks of the project." do
      argument :minimum_access_level,
        type: ::Types::AccessLevelEnum,
        required: false,
        description: 'Minimum access level.'
    end

    field :flow_metrics,
      ::Types::Analytics::CycleAnalytics::FlowMetrics[:project],
      null: true,
      description: 'Flow metrics for value stream analytics.',
      method: :project_namespace,
      authorize: :read_cycle_analytics,
      experiment: { milestone: '15.10' }

    field :commit_references, ::Types::CommitReferencesType,
      null: true,
      resolver: Resolvers::Projects::CommitReferencesResolver,
      experiment: { milestone: '16.0' },
      description: "Get tag names containing a given commit."

    field :autocomplete_users,
      null: true,
      resolver: Resolvers::AutocompleteUsersResolver,
      description: 'Search users for autocompletion'

    field :detailed_import_status,
      ::Types::Projects::DetailedImportStatusType,
      null: true,
      description: 'Detailed import status of the project.',
      method: :import_state

    field :value_streams,
      description: 'Value streams available to the project.',
      null: true,
      resolver: Resolvers::Analytics::CycleAnalytics::ValueStreamsResolver

    field :ml_models, ::Types::Ml::ModelType.connection_type,
      null: true,
      experiment: { milestone: '16.8' },
      description: 'Finds machine learning models',
      resolver: Resolvers::Ml::FindModelsResolver

    field :ml_experiments, ::Types::Ml::ExperimentType.connection_type,
      null: true,
      description: 'Find machine learning experiments',
      resolver: ::Resolvers::Ml::FindExperimentsResolver

    field :allows_multiple_merge_request_assignees,
      GraphQL::Types::Boolean,
      method: :allows_multiple_merge_request_assignees?,
      description: 'Project allows assigning multiple users to a merge request.',
      null: false

    field :allows_multiple_merge_request_reviewers,
      GraphQL::Types::Boolean,
      method: :allows_multiple_merge_request_reviewers?,
      description: 'Project allows assigning multiple reviewers to a merge request.',
      null: false

    field :is_forked,
      GraphQL::Types::Boolean,
      resolver: Resolvers::Projects::IsForkedResolver,
      description: 'Project is forked.',
      null: false

    field :protectable_branches,
      [GraphQL::Types::String],
      description: 'List of unprotected branches, ignoring any wildcard branch rules',
      null: true,
      calls_gitaly: true,
      experiment: { milestone: '16.9' },
      authorize: :read_code

    field :project_plan_limits, Types::ProjectPlanLimitsType,
      resolver: Resolvers::Projects::PlanLimitsResolver,
      description: 'Plan limits for the current project.',
      experiment: { milestone: '16.9' },
      null: true

    field :available_deploy_keys, Types::AccessLevels::DeployKeyType.connection_type,
      resolver: Resolvers::Projects::DeployKeyResolver,
      description: 'List of available deploy keys',
      extras: [:lookahead],
      null: true,
      authorize: :admin_project do
        argument :title_query, GraphQL::Types::String,
          required: false,
          description: 'Term by which to search deploy key titles'
      end

    field :pages_deployments, Types::PagesDeploymentType.connection_type, null: true,
      resolver: Resolvers::PagesDeploymentsResolver,
      connection: true,
      description: "List of the project's Pages Deployments."

    field :allowed_custom_statuses, Types::WorkItems::Widgets::CustomStatusType.connection_type,
      null: true, description: 'Allowed custom statuses for the project.',
      experiment: { milestone: '17.8' }, resolver: Resolvers::WorkItems::Widgets::CustomStatusResolver

    field :pages_force_https, GraphQL::Types::Boolean,
      null: false,
      description: "Project's Pages site redirects unsecured connections to HTTPS."

    field :pages_use_unique_domain, GraphQL::Types::Boolean,
      null: false,
      description: "Project's Pages site uses a unique subdomain."

    def ci_pipeline_creation_request(request_id:)
      ::Ci::PipelineCreation::Requests.get_request(object, request_id)
    end

    def pages_force_https
      project.pages_https_only?
    end

    def pages_use_unique_domain
      lazy_project_settings = BatchLoader::GraphQL.for(object.id).batch do |project_ids, loader|
        ::ProjectSetting.for_projects(project_ids).each do |project_setting|
          loader.call(project_setting.project_id, project_setting)
        end
      end

      Gitlab::Graphql::Lazy.with_value(lazy_project_settings) do |settings|
        (settings || object.project_setting).pages_unique_domain_enabled?
      end
    end

    def protectable_branches
      ProtectableDropdown.new(project, :branches).protectable_ref_names
    end

    def timelog_categories
      object.project_namespace.timelog_categories if Feature.enabled?(:timelog_categories)
    end

    def label(title:)
      BatchLoader::GraphQL.for(title).batch(key: project) do |titles, loader, args|
        LabelsFinder
          .new(current_user, project: args[:key], title: titles)
          .execute
          .each { |label| loader.call(label.title, label) }
      end
    end

    {
      issues: "Issues are",
      merge_requests: "Merge requests are",
      wiki: 'Wikis are',
      snippets: 'Snippets are',
      container_registry: 'Container Registry is'
    }.each do |feature, name_string|
      field "#{feature}_enabled", GraphQL::Types::Boolean, null: true,
        description: "Indicates if #{name_string} enabled for the current user"

      define_method "#{feature}_enabled" do
        object.feature_available?(feature, context[:current_user])
      end
    end

    [:issues, :forking, :merge_requests].each do |feature|
      field_name = "#{feature}_access_level"
      feature_name = feature.to_s.tr("_", " ")

      field field_name, Types::ProjectFeatureAccessLevelType,
        null: true,
        description: "Access level required for #{feature_name} access."

      define_method field_name do
        project.project_feature&.access_level(feature)
      end
    end

    markdown_field :description_html, null: true

    def avatar_url
      object.avatar_url(only_path: false)
    end

    def jobs_enabled
      object.feature_available?(:builds, context[:current_user])
    end

    def open_issues_count
      BatchLoader::GraphQL.wrap(object.open_issues_count) if object.feature_available?(:issues, context[:current_user])
    end

    def open_merge_requests_count
      return unless object.feature_available?(:merge_requests, context[:current_user])

      BatchLoader::GraphQL.wrap(object.open_merge_requests_count)
    end

    def forks_count
      BatchLoader::GraphQL.wrap(object.forks_count)
    end

    def is_catalog_resource # rubocop:disable Naming/PredicateName
      lazy_catalog_resource = BatchLoader::GraphQL.for(object.id).batch do |project_ids, loader|
        ::Ci::Catalog::Resource.for_projects(project_ids).each do |catalog_resource|
          loader.call(catalog_resource.project_id, catalog_resource)
        end
      end

      Gitlab::Graphql::Lazy.with_value(lazy_catalog_resource, &:present?)
    end

    def explore_catalog_path
      return unless project.catalog_resource

      Gitlab::Routing.url_helpers.explore_catalog_path(project.catalog_resource)
    end

    def statistics
      Gitlab::Graphql::Loaders::BatchProjectStatisticsLoader.new(object.id).find
    end

    def container_repositories_count
      project.container_repositories.size
    end

    def ci_config_variables(ref:)
      result = ::Ci::ListConfigVariablesService.new(object, context[:current_user]).execute(ref)

      return if result.nil?

      result.map do |var_key, var_config|
        { key: var_key, **var_config }
      end
    end

    def job(id:)
      object.commit_statuses.find(id.model_id)
    rescue ActiveRecord::RecordNotFound
    end

    def sast_ci_configuration
      return unless Ability.allowed?(current_user, :read_code, object)

      if project.repository.empty?
        raise Gitlab::Graphql::Errors::MutationError,
          _(format('You must %s before using Security features.', add_file_docs_link.html_safe)).html_safe
      end

      ::Security::CiConfiguration::SastParserService.new(object).configuration
    end

    def service_desk_address
      return unless Ability.allowed?(current_user, :admin_issue, project)

      ::ServiceDesk::Emails.new(object).address
    end

    def service_desk_enabled
      ::ServiceDesk.enabled?(project)
    end

    def languages
      ::Projects::RepositoryLanguagesService.new(project, current_user).execute
    end

    def visible_forks(minimum_access_level: nil)
      if minimum_access_level.nil?
        object.forks.public_or_visible_to_user(current_user)
      else
        return [] if current_user.nil?

        object.forks.visible_to_user_and_access_level(current_user, minimum_access_level)
      end
    end

    def statistics_details_paths
      root_ref = project.repository.root_ref || project.default_branch_or_main

      {
        repository: Gitlab::Routing.url_helpers.project_tree_url(project, root_ref),
        wiki: Gitlab::Routing.url_helpers.project_wikis_pages_url(project),
        build_artifacts: Gitlab::Routing.url_helpers.project_artifacts_url(project),
        packages: Gitlab::Routing.url_helpers.project_packages_url(project),
        snippets: Gitlab::Routing.url_helpers.project_snippets_url(project),
        container_registry: Gitlab::Routing.url_helpers.project_container_registry_index_url(project)
      }
    end

    def max_access_level
      return Gitlab::Access::NO_ACCESS if current_user.nil?

      BatchLoader::GraphQL.for(object.id).batch do |project_ids, loader|
        current_user.max_member_access_for_project_ids(project_ids).each do |project_id, max_access_level|
          loader.call(project_id, max_access_level)
        end
      end
    end

    def organization_edit_path
      return if project.organization.nil?

      ::Gitlab::Routing.url_helpers.edit_namespace_projects_organization_path(
        project.organization,
        id: project.to_param,
        namespace_id: project.namespace.to_param
      )
    end

    def container_protection_tag_rules
      return [] unless Feature.enabled?(:container_registry_protected_tags, object)

      object.container_registry_protection_tag_rules
    end

    private

    def project
      @project ||= object.respond_to?(:sync) ? object.sync : object
    end

    def add_file_docs_link
      ActionController::Base.helpers.link_to _('add at least one file to the repository'),
        Rails.application.routes.url_helpers.help_page_url(
          'user/project/repository/_index.md',
          anchor: 'add-files-to-a-repository'),
        target: '_blank',
        rel: 'noopener noreferrer'
    end
  end
end

Types::ProjectType.prepend_mod_with('Types::ProjectType')
