# frozen_string_literal: true

module Types
  module UserInterface
    include Types::BaseInterface

    graphql_name 'User'
    description 'Representation of a GitLab user.'

    field :user_permissions,
          type: Types::PermissionTypes::User,
          description: 'Permissions for the current user on the resource.',
          null: false,
          method: :itself

    field :id,
          type: GraphQL::Types::ID,
          null: false,
          description: 'ID of the user.'
    field :bot,
          type: GraphQL::Types::Boolean,
          null: false,
          description: 'Indicates if the user is a bot.',
          method: :bot?
    field :username,
          type: GraphQL::Types::String,
          null: false,
          description: 'Username of the user. Unique within this instance of GitLab.'
    field :name,
          type: GraphQL::Types::String,
          null: false,
          description: 'Human-readable name of the user.'
    field :state,
          type: Types::UserStateEnum,
          null: false,
          description: 'State of the user.'
    field :email,
          type: GraphQL::Types::String,
          null: true,
          description: 'User email.', method: :public_email,
          deprecated: { reason: :renamed, replacement: 'User.publicEmail', milestone: '13.7' }
    field :public_email,
          type: GraphQL::Types::String,
          null: true,
          description: "User's public email."
    field :avatar_url,
          type: GraphQL::Types::String,
          null: true,
          description: "URL of the user's avatar."
    field :web_url,
          type: GraphQL::Types::String,
          null: false,
          description: 'Web URL of the user.'
    field :web_path,
          type: GraphQL::Types::String,
          null: false,
          description: 'Web path of the user.'
    field :todos,
          resolver: Resolvers::TodoResolver,
          description: 'To-do items of the user.'
    field :group_memberships,
          type: Types::GroupMemberType.connection_type,
          null: true,
          description: 'Group memberships of the user.'
    field :group_count,
          resolver: Resolvers::Users::GroupCountResolver,
          description: 'Group count for the user.'
    field :status,
          type: Types::UserStatusType,
          null: true,
          description: 'User status.'
    field :location,
          type: ::GraphQL::Types::String,
          null: true,
          description: 'The location of the user.'
    field :project_memberships,
          type: Types::ProjectMemberType.connection_type,
          null: true,
          description: 'Project memberships of the user.'
    field :starred_projects,
          description: 'Projects starred by the user.',
          resolver: Resolvers::UserStarredProjectsResolver

    # Merge request field: MRs can be authored, assigned, or assigned-for-review:
    field :authored_merge_requests,
          resolver: Resolvers::AuthoredMergeRequestsResolver,
          description: 'Merge requests authored by the user.'
    field :assigned_merge_requests,
          resolver: Resolvers::AssignedMergeRequestsResolver,
          description: 'Merge requests assigned to the user.'
    field :review_requested_merge_requests,
          resolver: Resolvers::ReviewRequestedMergeRequestsResolver,
          description: 'Merge requests assigned to the user for review.'

    field :snippets,
          description: 'Snippets authored by the user.',
          resolver: Resolvers::Users::SnippetsResolver
    field :callouts,
          Types::UserCalloutType.connection_type,
          null: true,
          description: 'User callouts that belong to the user.'

    definition_methods do
      def resolve_type(object, context)
        # in the absense of other information, we cannot tell - just default to
        # the core user type.
        ::Types::UserType
      end
    end
  end
end
