# frozen_string_literal: true

module Types
  class IssueType < BaseObject
    graphql_name 'Issue'

    connection_type_class(Types::IssueConnectionType)

    implements(Types::Notes::NoteableType)
    implements(Types::CurrentUserTodos)

    authorize :read_issue

    expose_permissions Types::PermissionTypes::Issue

    present_using IssuePresenter

    field :id, GraphQL::ID_TYPE, null: false,
          description: "ID of the issue."
    field :iid, GraphQL::ID_TYPE, null: false,
          description: "Internal ID of the issue."
    field :title, GraphQL::STRING_TYPE, null: false,
          description: 'Title of the issue.'
    markdown_field :title_html, null: true
    field :description, GraphQL::STRING_TYPE, null: true,
          description: 'Description of the issue.'
    markdown_field :description_html, null: true
    field :state, IssueStateEnum, null: false,
          description: 'State of the issue.'

    field :reference, GraphQL::STRING_TYPE, null: false,
          description: 'Internal reference of the issue. Returned in shortened format by default.',
          method: :to_reference do
      argument :full, GraphQL::BOOLEAN_TYPE, required: false, default_value: false,
               description: 'Boolean option specifying whether the reference should be returned in full.'
    end

    field :author, Types::UserType, null: false,
          description: 'User that created the issue.'

    field :assignees, Types::UserType.connection_type, null: true,
          description: 'Assignees of the issue.'

    field :updated_by, Types::UserType, null: true,
          description: 'User that last updated the issue.'

    field :labels, Types::LabelType.connection_type, null: true,
          description: 'Labels of the issue.'
    field :milestone, Types::MilestoneType, null: true,
          description: 'Milestone of the issue.'

    field :due_date, Types::TimeType, null: true,
          description: 'Due date of the issue.'
    field :confidential, GraphQL::BOOLEAN_TYPE, null: false,
          description: 'Indicates the issue is confidential.'
    field :discussion_locked, GraphQL::BOOLEAN_TYPE, null: false,
          description: 'Indicates discussion is locked on the issue.'

    field :upvotes, GraphQL::INT_TYPE, null: false,
          description: 'Number of upvotes the issue has received.'
    field :downvotes, GraphQL::INT_TYPE, null: false,
          description: 'Number of downvotes the issue has received.'
    field :user_notes_count, GraphQL::INT_TYPE, null: false,
          description: 'Number of user notes of the issue.',
          resolver: Resolvers::UserNotesCountResolver
    field :user_discussions_count, GraphQL::INT_TYPE, null: false,
          description: 'Number of user discussions in the issue.',
          resolver: Resolvers::UserDiscussionsCountResolver
    field :web_path, GraphQL::STRING_TYPE, null: false, method: :issue_path,
          description: 'Web path of the issue.'
    field :web_url, GraphQL::STRING_TYPE, null: false,
          description: 'Web URL of the issue.'
    field :relative_position, GraphQL::INT_TYPE, null: true,
          description: 'Relative position of the issue (used for positioning in epic tree and issue boards).'

    field :participants, Types::UserType.connection_type, null: true, complexity: 5,
          description: 'List of participants in the issue.'
    field :emails_disabled, GraphQL::BOOLEAN_TYPE, null: false,
          method: :project_emails_disabled?,
          description: 'Indicates if a project has email notifications disabled: `true` if email notifications are disabled.'
    field :subscribed, GraphQL::BOOLEAN_TYPE, method: :subscribed?, null: false, complexity: 5,
          description: 'Indicates the currently logged in user is subscribed to the issue.'
    field :time_estimate, GraphQL::INT_TYPE, null: false,
          description: 'Time estimate of the issue.'
    field :total_time_spent, GraphQL::INT_TYPE, null: false,
          description: 'Total time reported as spent on the issue.'
    field :human_time_estimate, GraphQL::STRING_TYPE, null: true,
          description: 'Human-readable time estimate of the issue.'
    field :human_total_time_spent, GraphQL::STRING_TYPE, null: true,
          description: 'Human-readable total time reported as spent on the issue.'

    field :closed_at, Types::TimeType, null: true,
          description: 'Timestamp of when the issue was closed.'

    field :created_at, Types::TimeType, null: false,
          description: 'Timestamp of when the issue was created.'
    field :updated_at, Types::TimeType, null: false,
          description: 'Timestamp of when the issue was last updated.'

    field :task_completion_status, Types::TaskCompletionStatus, null: false,
          description: 'Task completion status of the issue.'

    field :design_collection, Types::DesignManagement::DesignCollectionType, null: true,
          description: 'Collection of design images associated with this issue.'

    field :type, Types::IssueTypeEnum, null: true,
          method: :issue_type,
          description: 'Type of the issue.'

    field :alert_management_alert,
          Types::AlertManagement::AlertType,
          null: true,
          description: 'Alert associated to this issue.'

    field :severity, Types::IssuableSeverityEnum, null: true,
          description: 'Severity level of the incident.'

    field :moved, GraphQL::BOOLEAN_TYPE, method: :moved?, null: true,
          description: 'Indicates if issue got moved from other project.'

    field :moved_to, Types::IssueType, null: true,
          description: 'Updated Issue after it got moved to another project.'

    field :create_note_email, GraphQL::STRING_TYPE, null: true,
          description: 'User specific email address for the issue.'

    field :timelogs, Types::TimelogType.connection_type, null: false,
          description: 'Timelogs on the issue.'

    field :project_id, GraphQL::INT_TYPE, null: false, method: :project_id,
          description: 'ID of the issue project.'

    def author
      Gitlab::Graphql::Loaders::BatchModelLoader.new(User, object.author_id).find
    end

    def updated_by
      Gitlab::Graphql::Loaders::BatchModelLoader.new(User, object.updated_by_id).find
    end

    def milestone
      Gitlab::Graphql::Loaders::BatchModelLoader.new(Milestone, object.milestone_id).find
    end

    def moved_to
      Gitlab::Graphql::Loaders::BatchModelLoader.new(Issue, object.moved_to_id).find
    end

    def discussion_locked
      !!object.discussion_locked
    end

    def create_note_email
      object.creatable_note_email_address(context[:current_user])
    end
  end
end

Types::IssueType.prepend_mod_with('Types::IssueType')
