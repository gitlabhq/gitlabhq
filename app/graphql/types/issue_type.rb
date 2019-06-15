# frozen_string_literal: true

module Types
  class IssueType < BaseObject
    graphql_name 'Issue'

    authorize :read_issue

    expose_permissions Types::PermissionTypes::Issue

    present_using IssuePresenter

    field :iid, GraphQL::ID_TYPE, null: false
    field :title, GraphQL::STRING_TYPE, null: false
    field :description, GraphQL::STRING_TYPE, null: true
    field :state, IssueStateEnum, null: false

    field :reference, GraphQL::STRING_TYPE, null: false, method: :to_reference do
      argument :full, GraphQL::BOOLEAN_TYPE, required: false, default_value: false
    end

    field :author, Types::UserType,
          null: false,
          resolve: -> (obj, _args, _ctx) { Gitlab::Graphql::Loaders::BatchModelLoader.new(User, obj.author_id).find }

    # Remove complexity when BatchLoader is used
    field :assignees, Types::UserType.connection_type, null: true, complexity: 5

    # Remove complexity when BatchLoader is used
    field :labels, Types::LabelType.connection_type, null: true, complexity: 5
    field :milestone, Types::MilestoneType,
          null: true,
          resolve: -> (obj, _args, _ctx) { Gitlab::Graphql::Loaders::BatchModelLoader.new(Milestone, obj.milestone_id).find }

    field :due_date, Types::TimeType, null: true
    field :confidential, GraphQL::BOOLEAN_TYPE, null: false
    field :discussion_locked, GraphQL::BOOLEAN_TYPE,
          null: false,
          resolve: -> (obj, _args, _ctx) { !!obj.discussion_locked }

    field :upvotes, GraphQL::INT_TYPE, null: false
    field :downvotes, GraphQL::INT_TYPE, null: false
    field :user_notes_count, GraphQL::INT_TYPE, null: false
    field :web_path, GraphQL::STRING_TYPE, null: false, method: :issue_path
    field :web_url, GraphQL::STRING_TYPE, null: false
    field :relative_position, GraphQL::INT_TYPE, null: true

    field :closed_at, Types::TimeType, null: true

    field :created_at, Types::TimeType, null: false
    field :updated_at, Types::TimeType, null: false

    field :task_completion_status, Types::TaskCompletionStatus, null: false
  end
end
