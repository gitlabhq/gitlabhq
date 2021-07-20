# frozen_string_literal: true

module Types
  class QueryType < ::Types::BaseObject
    graphql_name 'Query'

    # The design management context object needs to implement #issue
    DesignManagementObject = Struct.new(:issue)

    field :project, Types::ProjectType,
          null: true,
          resolver: Resolvers::ProjectResolver,
          description: "Find a project."

    field :projects, Types::ProjectType.connection_type,
          null: true,
          resolver: Resolvers::ProjectsResolver,
          description: "Find projects visible to the current user."

    field :group, Types::GroupType,
          null: true,
          resolver: Resolvers::GroupResolver,
          description: "Find a group."

    field :current_user, Types::UserType,
          null: true,
          description: "Get information about current user."

    field :namespace, Types::NamespaceType,
          null: true,
          resolver: Resolvers::NamespaceResolver,
          description: "Find a namespace."

    field :metadata, Types::MetadataType,
          null: true,
          resolver: Resolvers::MetadataResolver,
          description: 'Metadata about GitLab.'

    field :query_complexity, Types::QueryComplexityType,
          null: true,
          description: 'Information about the complexity of the GraphQL query.'

    field :snippets,
          Types::SnippetType.connection_type,
          null: true,
          resolver: Resolvers::SnippetsResolver,
          description: 'Find Snippets visible to the current user.'

    field :design_management, Types::DesignManagementType,
          null: false,
          description: 'Fields related to design management.'

    field :milestone, ::Types::MilestoneType,
          null: true,
          description: 'Find a milestone.' do
            argument :id, ::Types::GlobalIDType[Milestone], required: true, description: 'Find a milestone by its ID.'
          end

    field :container_repository, Types::ContainerRepositoryDetailsType,
          null: true,
          description: 'Find a container repository.' do
            argument :id,
                     type: ::Types::GlobalIDType[::ContainerRepository],
                     required: true,
                     description: 'The global ID of the container repository.'
          end

    field :package,
          description: 'Find a package.',
          resolver: Resolvers::PackageDetailsResolver

    field :user, Types::UserType,
          null: true,
          description: 'Find a user.',
          resolver: Resolvers::UserResolver

    field :users, Types::UserType.connection_type,
          null: true,
          description: 'Find users.',
          resolver: Resolvers::UsersResolver

    field :echo, resolver: Resolvers::EchoResolver

    field :issue, Types::IssueType,
          null: true,
          description: 'Find an issue.' do
            argument :id, ::Types::GlobalIDType[::Issue], required: true, description: 'The global ID of the issue.'
          end

    field :merge_request, Types::MergeRequestType,
          null: true,
          description: 'Find a merge request.' do
            argument :id, ::Types::GlobalIDType[::MergeRequest], required: true, description: 'The global ID of the merge request.'
          end

    field :instance_statistics_measurements,
          type: Types::Admin::Analytics::UsageTrends::MeasurementType.connection_type,
          null: true,
          description: 'Get statistics on the instance.',
          resolver: Resolvers::Admin::Analytics::UsageTrends::MeasurementsResolver,
          deprecated: {
            reason: :renamed,
            replacement: 'Query.usageTrendsMeasurements',
            milestone: '13.10'
          }

    field :usage_trends_measurements, Types::Admin::Analytics::UsageTrends::MeasurementType.connection_type,
          null: true,
          description: 'Get statistics on the instance.',
          resolver: Resolvers::Admin::Analytics::UsageTrends::MeasurementsResolver

    field :ci_application_settings, Types::Ci::ApplicationSettingType,
          null: true,
          description: 'CI related settings that apply to the entire instance.'

    field :runner_platforms, resolver: Resolvers::Ci::RunnerPlatformsResolver
    field :runner_setup, resolver: Resolvers::Ci::RunnerSetupResolver

    field :runner, Types::Ci::RunnerType,
          null: true,
          resolver: Resolvers::Ci::RunnerResolver,
          extras: [:lookahead],
          description: "Find a runner.",
          feature_flag: :runner_graphql_query

    field :runners, Types::Ci::RunnerType.connection_type,
          null: true,
          resolver: Resolvers::Ci::RunnersResolver,
          description: "Find runners visible to the current user.",
          feature_flag: :runner_graphql_query

    field :ci_config, resolver: Resolvers::Ci::ConfigResolver, complexity: 126 # AUTHENTICATED_COMPLEXITY / 2 + 1

    def design_management
      DesignManagementObject.new(nil)
    end

    def issue(id:)
      # TODO: remove this line when the compatibility layer is removed
      # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
      id = ::Types::GlobalIDType[::Issue].coerce_isolated_input(id)
      GitlabSchema.find_by_gid(id)
    end

    def merge_request(id:)
      # TODO: remove this line when the compatibility layer is removed
      # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
      id = ::Types::GlobalIDType[::MergeRequest].coerce_isolated_input(id)
      GitlabSchema.find_by_gid(id)
    end

    def milestone(id:)
      # TODO: remove this line when the compatibility layer is removed
      # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
      id = ::Types::GlobalIDType[Milestone].coerce_isolated_input(id)
      GitlabSchema.find_by_gid(id)
    end

    def container_repository(id:)
      # TODO: remove this line when the compatibility layer is removed
      # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
      id = ::Types::GlobalIDType[::ContainerRepository].coerce_isolated_input(id)
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

    def query_complexity
      context.query
    end
  end
end

Types::QueryType.prepend_mod_with('Types::QueryType')
