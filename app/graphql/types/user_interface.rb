# frozen_string_literal: true

module Types
  module UserInterface
    include Types::BaseInterface

    graphql_name 'User'
    description 'Representation of a GitLab user.'

    implements Types::TodoableInterface

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
      resolver_method: :redacted_name,
      description: 'Human-readable name of the user. ' \
        'Returns `****` if the user is a project bot and the requester does not have permission to view the project.'

    field :state,
      type: Types::UserStateEnum,
      null: false,
      description: 'State of the user.'
    field :email,
      type: GraphQL::Types::String,
      null: true,
      description: 'User email.', method: :public_email,
      deprecated: { reason: :renamed, replacement: 'User.publicEmail', milestone: '13.7' }
    field :emails,
      type: Types::Users::EmailType.connection_type,
      null: true,
      description: "User's email addresses."
    field :public_email,
      type: GraphQL::Types::String,
      null: true,
      description: "User's public email."
    field :commit_email,
      type: GraphQL::Types::String,
      null: true,
      description: "User's default commit email.",
      authorize: :read_user_email_address
    field :namespace_commit_emails,
      type: Types::Users::NamespaceCommitEmailType.connection_type,
      null: true,
      description: "User's custom namespace commit emails."
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
    field :organizations,
      resolver: Resolvers::Users::OrganizationsResolver,
      null: true,
      experiment: { milestone: '16.6' },
      description: 'Organizations where the user has access.'
    field :group_memberships,
      type: Types::GroupMemberType.connection_type,
      null: true,
      description: 'Group memberships of the user.'
    field :groups,
      resolver: Resolvers::Users::GroupsResolver,
      description: 'Groups where the user has access.'
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
      description: 'Location of the user.'
    field :project_memberships,
      type: Types::ProjectMemberType.connection_type,
      null: true,
      description: 'Project memberships of the user.'
    field :starred_projects,
      description: 'Projects starred by the user.',
      resolver: Resolvers::UserStarredProjectsResolver
    field :contributed_projects,
      description: 'Projects the user has contributed to.',
      resolver: Resolvers::Projects::UserContributedProjectsResolver
    field :namespace,
      type: Types::NamespaceType,
      null: true,
      description: 'Personal namespace of the user.'

    field :todos,
      Types::TodoType.connection_type,
      description: 'To-do items of the user.',
      resolver: Resolvers::TodosResolver

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
    field :timelogs,
      Types::TimelogType.connection_type,
      null: true,
      description: 'Time logged by the user.',
      extras: [:lookahead],
      complexity: 5,
      resolver: ::Resolvers::TimelogResolver
    field :saved_replies,
      ::Types::Users::SavedReplyType.connection_type,
      null: true,
      description: 'Saved replies authored by the user.'

    field :saved_reply,
      resolver: Resolvers::SavedReplyResolver,
      description: 'Saved reply authored by the user.'

    field :gitpod_enabled, GraphQL::Types::Boolean, null: true,
      description: 'Whether Gitpod is enabled at the user level.'

    field :user_preferences, ::Types::UserPreferencesType,
      null: true,
      description: 'Preferences for the user.',
      method: :user_preference

    field :preferences_gitpod_path,
      GraphQL::Types::String,
      null: true,
      description: 'Web path to the Gitpod section within user preferences.'

    field :profile_enable_gitpod_path, GraphQL::Types::String, null: true,
      description: 'Web path to enable Gitpod for the user.'

    field :user_achievements,
      Types::Achievements::UserAchievementType.connection_type,
      null: true,
      experiment: { milestone: '15.10' },
      description: "Achievements for the user. " \
        "Only returns for namespaces where the `achievements` feature flag is enabled.",
      extras: [:lookahead],
      resolver: ::Resolvers::Achievements::UserAchievementsForUserResolver

    field :bio,
      type: ::GraphQL::Types::String,
      null: true,
      description: 'Bio of the user.'

    field :active,
      type: ::GraphQL::Types::Boolean,
      null: true,
      method: :active?,
      description: 'Indicates if the user is active.'

    field :human,
      type: ::GraphQL::Types::Boolean,
      null: true,
      method: :human?,
      description: 'Indicates if the user is a regular user.'

    field :linkedin,
      type: ::GraphQL::Types::String,
      null: true,
      description: 'LinkedIn profile name of the user.'

    field :twitter,
      type: ::GraphQL::Types::String,
      null: true,
      description: 'X (formerly Twitter) username of the user.'

    field :discord,
      type: ::GraphQL::Types::String,
      null: true,
      description: 'Discord ID of the user.'

    field :organization,
      type: ::GraphQL::Types::String,
      null: true,
      description: 'Who the user represents or works for.'

    field :job_title,
      type: ::GraphQL::Types::String,
      null: true,
      description: 'Job title of the user.'

    field :created_at,
      type: Types::TimeType,
      null: true,
      description: 'Timestamp of when the user was created.'

    field :last_activity_on,
      type: Types::DateType,
      null: true,
      description: 'Date the user last performed any actions.'

    field :pronouns,
      type: ::GraphQL::Types::String,
      null: true,
      description: 'Pronouns of the user.'

    field :ide,
      type: Types::IdeType,
      null: true,
      description: 'IDE settings.',
      method: :itself

    field :type,
      type: Types::Users::TypeEnum,
      null: false,
      description: 'Type of the user.',
      method: :user_type

    definition_methods do
      def resolve_type(object, context)
        # in the absence of other information, we cannot tell - just default to
        # the core user type.
        ::Types::UserType
      end
    end

    def redacted_name
      object.redacted_name(context[:current_user])
    end
  end
end
