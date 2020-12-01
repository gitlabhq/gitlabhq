# frozen_string_literal: true

module Types
  class QueryType < ::Types::BaseObject
    graphql_name 'Query'

    # The design management context object needs to implement #issue
    DesignManagementObject = Struct.new(:issue)

    field :project, Types::ProjectType,
          null: true,
          resolver: Resolvers::ProjectResolver,
          description: "Find a project"

    field :projects, Types::ProjectType.connection_type,
          null: true,
          resolver: Resolvers::ProjectsResolver,
          description: "Find projects visible to the current user"

    field :group, Types::GroupType,
          null: true,
          resolver: Resolvers::GroupResolver,
          description: "Find a group"

    field :current_user, Types::UserType,
          null: true,
          description: "Get information about current user"

    field :namespace, Types::NamespaceType,
          null: true,
          resolver: Resolvers::NamespaceResolver,
          description: "Find a namespace"

    field :metadata, Types::MetadataType,
          null: true,
          resolver: Resolvers::MetadataResolver,
          description: 'Metadata about GitLab'

    field :snippets,
          Types::SnippetType.connection_type,
          null: true,
          resolver: Resolvers::SnippetsResolver,
          description: 'Find Snippets visible to the current user'

    field :design_management, Types::DesignManagementType,
          null: false,
          description: 'Fields related to design management'

    field :milestone, ::Types::MilestoneType,
          null: true,
          description: 'Find a milestone' do
            argument :id, ::Types::GlobalIDType[Milestone], required: true, description: 'Find a milestone by its ID'
          end

    field :container_repository, Types::ContainerRepositoryDetailsType,
          null: true,
          description: 'Find a container repository' do
            argument :id, ::Types::GlobalIDType[::ContainerRepository], required: true, description: 'The global ID of the container repository'
          end

    field :user, Types::UserType,
          null: true,
          description: 'Find a user',
          resolver: Resolvers::UserResolver

    field :users, Types::UserType.connection_type,
          null: true,
          description: 'Find users',
          resolver: Resolvers::UsersResolver

    field :echo, GraphQL::STRING_TYPE, null: false,
          description: 'Text to echo back',
          resolver: Resolvers::EchoResolver

    field :issue, Types::IssueType,
          null: true,
          description: 'Find an issue' do
            argument :id, ::Types::GlobalIDType[::Issue], required: true, description: 'The global ID of the Issue'
          end

    field :instance_statistics_measurements, Types::Admin::Analytics::InstanceStatistics::MeasurementType.connection_type,
          null: true,
          description: 'Get statistics on the instance',
          resolver: Resolvers::Admin::Analytics::InstanceStatistics::MeasurementsResolver

    field :runner_platforms, Types::Ci::RunnerPlatformType.connection_type,
      null: true, description: 'Supported runner platforms',
      resolver: Resolvers::Ci::RunnerPlatformsResolver

    field :runner_setup, Types::Ci::RunnerSetupType, null: true,
      description: 'Get runner setup instructions',
      resolver: Resolvers::Ci::RunnerSetupResolver

    def design_management
      DesignManagementObject.new(nil)
    end

    def issue(id:)
      # TODO: remove this line when the compatibility layer is removed
      # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
      id = ::Types::GlobalIDType[::Issue].coerce_isolated_input(id)
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
  end
end

Types::QueryType.prepend_if_ee('EE::Types::QueryType')
