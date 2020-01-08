# frozen_string_literal: true

module Types
  class IssueType < BaseObject
    graphql_name 'Issue'

    implements(Types::Notes::NoteableType)

    authorize :read_issue

    expose_permissions Types::PermissionTypes::Issue

    present_using IssuePresenter

    field :iid, GraphQL::ID_TYPE, null: false,
          description: "Internal ID of the issue"
    field :title, GraphQL::STRING_TYPE, null: false,
          description: 'Title of the issue'
    markdown_field :title_html, null: true
    field :description, GraphQL::STRING_TYPE, null: true,
          description: 'Description of the issue'
    markdown_field :description_html, null: true
    field :state, IssueStateEnum, null: false,
          description: 'State of the issue'

    field :reference, GraphQL::STRING_TYPE, null: false,
          description: 'Internal reference of the issue. Returned in shortened format by default',
          method: :to_reference do
      argument :full, GraphQL::BOOLEAN_TYPE, required: false, default_value: false,
               description: 'Boolean option specifying whether the reference should be returned in full'
    end

    field :author, Types::UserType, null: false,
          description: 'User that created the issue',
          resolve: -> (obj, _args, _ctx) { Gitlab::Graphql::Loaders::BatchModelLoader.new(User, obj.author_id).find }

    # Remove complexity when BatchLoader is used
    field :assignees, Types::UserType.connection_type, null: true, complexity: 5,
          description: 'Assignees of the issue'

    # Remove complexity when BatchLoader is used
    field :labels, Types::LabelType.connection_type, null: true, complexity: 5,
          description: 'Labels of the issue'
    field :milestone, Types::MilestoneType, null: true,
          description: 'Milestone of the issue',
          resolve: -> (obj, _args, _ctx) { Gitlab::Graphql::Loaders::BatchModelLoader.new(Milestone, obj.milestone_id).find }

    field :due_date, Types::TimeType, null: true,
          description: 'Due date of the issue'
    field :confidential, GraphQL::BOOLEAN_TYPE, null: false,
          description: 'Indicates the issue is confidential'
    field :discussion_locked, GraphQL::BOOLEAN_TYPE, null: false,
          description: 'Indicates discussion is locked on the issue',
          resolve: -> (obj, _args, _ctx) { !!obj.discussion_locked }

    field :upvotes, GraphQL::INT_TYPE, null: false,
          description: 'Number of upvotes the issue has received'
    field :downvotes, GraphQL::INT_TYPE, null: false,
          description: 'Number of downvotes the issue has received'
    field :user_notes_count, GraphQL::INT_TYPE, null: false,
          description: 'Number of user notes of the issue'
    field :web_path, GraphQL::STRING_TYPE, null: false, method: :issue_path,
          description: 'Web path of the issue'
    field :web_url, GraphQL::STRING_TYPE, null: false,
          description: 'Web URL of the issue'
    field :relative_position, GraphQL::INT_TYPE, null: true,
          description: 'Relative position of the issue (used for positioning in epic tree and issue boards)'

    field :participants, Types::UserType.connection_type, null: true, complexity: 5,
          description: 'List of participants in the issue'
    field :subscribed, GraphQL::BOOLEAN_TYPE, method: :subscribed?, null: false, complexity: 5,
          description: 'Indicates the currently logged in user is subscribed to the issue'
    field :time_estimate, GraphQL::INT_TYPE, null: false,
          description: 'Time estimate of the issue'
    field :total_time_spent, GraphQL::INT_TYPE, null: false,
          description: 'Total time reported as spent on the issue'

    field :closed_at, Types::TimeType, null: true,
          description: 'Timestamp of when the issue was closed'

    field :created_at, Types::TimeType, null: false,
          description: 'Timestamp of when the issue was created'
    field :updated_at, Types::TimeType, null: false,
          description: 'Timestamp of when the issue was last updated'

    field :task_completion_status, Types::TaskCompletionStatus, null: false,
          description: 'Task completion status of the issue'
  end
end

Types::IssueType.prepend_if_ee('::EE::Types::IssueType')
