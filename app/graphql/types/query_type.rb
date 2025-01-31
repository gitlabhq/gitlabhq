# frozen_string_literal: true

module Types
  class QueryType < ::Types::BaseObject
    graphql_name 'Query'

    # The design management context object needs to implement #issue
    DesignManagementObject = Struct.new(:issue)

    field :board_list, ::Types::BoardListType,
      null: true,
      resolver: Resolvers::BoardListResolver
    field :ci_application_settings, Types::Ci::ApplicationSettingType,
      null: true,
      description: 'CI related settings that apply to the entire instance.'
    field :ci_config, resolver: Resolvers::Ci::ConfigResolver, complexity: 126 # AUTHENTICATED_MAX_COMPLEXITY / 2 + 1

    field :ci_pipeline_stage, ::Types::Ci::StageType,
      null: true, description: 'Stage belonging to a CI pipeline.' do
      argument :id, type: ::Types::GlobalIDType[::Ci::Stage],
        required: true, description: 'Global ID of the CI stage.'
    end

    field :ci_catalog_resources,
      ::Types::Ci::Catalog::ResourceType.connection_type,
      null: true,
      experiment: { milestone: '15.11' },
      description: 'All CI/CD Catalog resources under a common namespace, visible to an authorized user',
      resolver: ::Resolvers::Ci::Catalog::ResourcesResolver

    field :ci_catalog_resource,
      ::Types::Ci::Catalog::ResourceType,
      null: true,
      experiment: { milestone: '16.1' },
      description: 'A single CI/CD Catalog resource visible to an authorized user',
      resolver: ::Resolvers::Ci::Catalog::ResourceResolver

    field :ci_variables,
      Types::Ci::InstanceVariableType.connection_type,
      null: true,
      description: "List of the instance's CI/CD variables.",
      resolver: Resolvers::Ci::VariablesResolver
    field :container_repository, Types::ContainerRegistry::ContainerRepositoryDetailsType,
      null: true,
      description: 'Find a container repository.' do
      argument :id,
        type: ::Types::GlobalIDType[::ContainerRepository],
        required: true,
        description: 'Global ID of the container repository.'
    end
    field :current_user, Types::CurrentUserType,
      null: true,
      description: "Get information about current user."
    field :design_management, Types::DesignManagementType,
      null: false,
      description: 'Fields related to design management.'
    field :echo, resolver: Resolvers::EchoResolver
    field :frecent_groups, [Types::GroupType],
      resolver: Resolvers::Users::FrecentGroupsResolver,
      description: "A user's frecently visited groups"
    field :frecent_projects, [Types::ProjectType],
      resolver: Resolvers::Users::FrecentProjectsResolver,
      description: "A user's frecently visited projects"
    field :gitpod_enabled, GraphQL::Types::Boolean,
      null: true,
      description: "Whether Gitpod is enabled in application settings."
    field :group, Types::GroupType,
      null: true,
      resolver: Resolvers::GroupResolver,
      description: "Find a group."
    field :groups, Types::GroupType.connection_type,
      null: true,
      resolver: Resolvers::GroupsResolver,
      description: "Find groups."
    field :issue, Types::IssueType,
      null: true,
      description: 'Find an issue.' do
      argument :id, ::Types::GlobalIDType[::Issue], required: true, description: 'Global ID of the issue.'
    end
    field :issues,
      null: true,
      experiment: { milestone: '15.6' },
      resolver: Resolvers::IssuesResolver,
      description: 'Find issues visible to the current user. ' \
        'At least one filter must be provided.'
    field :jobs,
      ::Types::Ci::JobType.connection_type,
      null: true,
      description: 'All jobs on this GitLab instance. ' \
        'Returns an empty result for users without administrator access.',
      resolver: ::Resolvers::Ci::AllJobsResolver
    field :merge_request, Types::MergeRequestType,
      null: true,
      description: 'Find a merge request.' do
      argument :id, ::Types::GlobalIDType[::MergeRequest], required: true, description: 'Global ID of the merge request.'
    end
    field :metadata, Types::AppConfig::InstanceMetadataType,
      null: true,
      resolver: Resolvers::AppConfig::InstanceMetadataResolver,
      description: 'Metadata about GitLab.'
    field :milestone, ::Types::MilestoneType,
      null: true,
      extras: [:lookahead],
      description: 'Find a milestone.' do
      argument :id, ::Types::GlobalIDType[Milestone], required: true, description: 'Find a milestone by its ID.'
    end
    field :namespace, Types::NamespaceType,
      null: true,
      resolver: Resolvers::NamespaceResolver,
      description: "Find a namespace."
    field :note,
      ::Types::Notes::NoteType,
      null: true,
      description: 'Find a note.',
      experiment: { milestone: '15.9' } do
      argument :id, ::Types::GlobalIDType[::Note],
        required: true,
        description: 'Global ID of the note.'
    end
    field :organization,
      Types::Organizations::OrganizationType,
      null: true,
      resolver: Resolvers::Organizations::OrganizationResolver,
      description: "Find an organization.",
      experiment: { milestone: '16.4' }
    field :organizations, Types::Organizations::OrganizationType.connection_type,
      null: true,
      resolver: Resolvers::Organizations::OrganizationsResolver,
      description: "List organizations.",
      experiment: { milestone: '16.8' }
    field :package,
      description: 'Find a package. This field can only be resolved for one query in any single request. Returns `null` if a package has no `default` status.',
      resolver: Resolvers::PackageDetailsResolver
    field :project, Types::ProjectType,
      null: true,
      resolver: Resolvers::ProjectResolver,
      description: "Find a project."
    field :projects,
      null: true,
      resolver: Resolvers::ProjectsResolver,
      description: "Find projects visible to the current user."
    field :query_complexity, Types::QueryComplexityType,
      null: true,
      description: 'Information about the complexity of the GraphQL query.'
    field :runner, Types::Ci::RunnerType,
      null: true,
      resolver: Resolvers::Ci::RunnerResolver,
      extras: [:lookahead],
      description: "Find a runner."
    field :runner_platforms, resolver: Resolvers::Ci::RunnerPlatformsResolver,
      deprecated: { reason: 'No longer used, use gitlab-runner documentation to learn about supported platforms', milestone: '15.9' }
    field :runner_setup, resolver: Resolvers::Ci::RunnerSetupResolver,
      deprecated: { reason: 'No longer used, use gitlab-runner documentation to learn about runner registration commands', milestone: '15.9' }
    field :runners, Types::Ci::RunnerType.connection_type,
      null: true,
      resolver: Resolvers::Ci::RunnersResolver,
      description: "Get all runners in the GitLab instance (project and shared). " \
        "Access is restricted to users with administrator access."
    field :snippets,
      Types::SnippetType.connection_type,
      null: true,
      resolver: Resolvers::SnippetsResolver,
      description: 'Find Snippets visible to the current user.'
    field :synthetic_note,
      Types::Notes::NoteType,
      null: true,
      description: 'Find a synthetic note',
      resolver: ::Resolvers::Notes::SyntheticNoteResolver,
      experiment: { milestone: '15.9' }
    field :timelogs, Types::TimelogType.connection_type,
      null: true,
      description: 'Find timelogs visible to the current user.',
      extras: [:lookahead],
      complexity: 5,
      resolver: ::Resolvers::TimelogResolver
    field :todo,
      null: true,
      resolver: Resolvers::TodoResolver
    field :topics, Types::Projects::TopicType.connection_type,
      null: true,
      resolver: Resolvers::TopicsResolver,
      description: "Find project topics."
    field :usage_trends_measurements,
      null: true,
      description: 'Get statistics on the instance.',
      resolver: Resolvers::Admin::Analytics::UsageTrends::MeasurementsResolver
    field :user, Types::UserType,
      null: true,
      description: 'Find a user.',
      resolver: Resolvers::UserResolver
    field :users, Types::UserType.connection_type,
      null: true,
      description: 'Find users.',
      resolver: Resolvers::UsersResolver
    field :wiki_page, Types::Wikis::WikiPageType,
      null: true,
      resolver: Resolvers::Wikis::WikiPageResolver,
      experiment: { milestone: '17.6' },
      description: 'Find a wiki page.'
    field :work_item, Types::WorkItemType,
      null: true,
      resolver: Resolvers::WorkItemResolver,
      experiment: { milestone: '15.1' },
      description: 'Find a work item.'

    field :work_item_description_template_content, WorkItems::DescriptionTemplateType,
      null: true,
      resolver: Resolvers::WorkItems::DescriptionTemplateContentResolver,
      experiment: { milestone: '17.9' },
      description: 'Find a work item description template.',
      calls_gitaly: true

    field :audit_event_definitions,
      Types::AuditEvents::DefinitionType.connection_type,
      null: false,
      description: 'Definitions for all audit events available on the instance.',
      resolver: Resolvers::AuditEvents::AuditEventDefinitionsResolver

    field :abuse_report, ::Types::AbuseReportType,
      null: true,
      experiment: { milestone: '16.3' },
      description: 'Find an abuse report.',
      resolver: Resolvers::AbuseReportResolver

    field :abuse_report_labels, ::Types::LabelType.connection_type,
      null: true,
      experiment: { milestone: '16.3' },
      description: 'Abuse report labels.',
      resolver: Resolvers::AbuseReportLabelsResolver

    field :ml_model, ::Types::Ml::ModelType,
      null: true,
      experiment: { milestone: '16.7' },
      description: 'Find machine learning models.',
      resolver: Resolvers::Ml::ModelDetailResolver

    field :ml_experiment, ::Types::Ml::ExperimentType,
      null: true,
      description: 'Find a machine learning experiment.',
      resolver: Resolvers::Ml::ExperimentDetailResolver

    field :integration_exclusions, Types::Integrations::ExclusionType.connection_type,
      null: true,
      experiment: { milestone: '17.0' },
      resolver: Resolvers::Integrations::ExclusionsResolver

    field :work_items_by_reference,
      null: true,
      experiment: { milestone: '16.7' },
      description: 'Find work items by their reference.',
      extras: [:lookahead],
      resolver: Resolvers::WorkItemReferencesResolver

    field :feature_flag_enabled, GraphQL::Types::Boolean,
      null: false,
      deprecated: { reason: 'Replaced with metadata.featureFlags', milestone: '17.4' },
      description: 'Check if a feature flag is enabled',
      resolver: Resolvers::FeatureFlagResolver

    def design_management
      DesignManagementObject.new(nil)
    end

    def issue(id:)
      GitlabSchema.find_by_gid(id)
    end

    def note(id:)
      GitlabSchema.find_by_gid(id)
    end

    def merge_request(id:)
      GitlabSchema.find_by_gid(id)
    end

    def milestone(id:, lookahead:)
      preloads = [:releases] if lookahead.selects?(:releases)
      Gitlab::Graphql::Loaders::BatchModelLoader.new(id.model_class, id.model_id, preloads).find
    end

    def container_repository(id:)
      GitlabSchema.find_by_gid(id)
    end

    def current_user
      context[:current_user]
    end

    def ci_application_settings
      application_settings
    end

    def application_settings
      Gitlab::CurrentSettings.current_application_settings
    end

    def gitpod_enabled
      application_settings.gitpod_enabled
    end

    def query_complexity
      context.query
    end

    def ci_pipeline_stage(id:)
      stage = ::Gitlab::Graphql::Lazy.force(GitlabSchema.find_by_gid(id))
      return unless stage

      authorized = Ability.allowed?(current_user, :read_build, stage.project)

      return unless authorized

      stage
    end
  end
end

Types::QueryType.prepend_mod_with('Types::QueryType')
