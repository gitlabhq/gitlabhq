# frozen_string_literal: true

module Types
  class IssueType < BaseObject
    graphql_name 'Issue'

    implements(Types::Notes::NoteableType)

    authorize :read_issue

    expose_permissions Types::PermissionTypes::Issue

    present_using IssuePresenter

    field :iid, GraphQL::ID_TYPE, null: false # rubocop:disable Graphql/Descriptions
    field :title, GraphQL::STRING_TYPE, null: false # rubocop:disable Graphql/Descriptions
    markdown_field :title_html, null: true
    field :description, GraphQL::STRING_TYPE, null: true # rubocop:disable Graphql/Descriptions
    markdown_field :description_html, null: true
    field :state, IssueStateEnum, null: false # rubocop:disable Graphql/Descriptions

    field :reference, GraphQL::STRING_TYPE, null: false, method: :to_reference do # rubocop:disable Graphql/Descriptions
      argument :full, GraphQL::BOOLEAN_TYPE, required: false, default_value: false # rubocop:disable Graphql/Descriptions
    end

    field :author, Types::UserType, # rubocop:disable Graphql/Descriptions
          null: false,
          resolve: -> (obj, _args, _ctx) { Gitlab::Graphql::Loaders::BatchModelLoader.new(User, obj.author_id).find }

    # Remove complexity when BatchLoader is used
    field :assignees, Types::UserType.connection_type, null: true, complexity: 5 # rubocop:disable Graphql/Descriptions

    # Remove complexity when BatchLoader is used
    field :labels, Types::LabelType.connection_type, null: true, complexity: 5 # rubocop:disable Graphql/Descriptions
    field :milestone, Types::MilestoneType, # rubocop:disable Graphql/Descriptions
          null: true,
          resolve: -> (obj, _args, _ctx) { Gitlab::Graphql::Loaders::BatchModelLoader.new(Milestone, obj.milestone_id).find }

    field :due_date, Types::TimeType, null: true # rubocop:disable Graphql/Descriptions
    field :confidential, GraphQL::BOOLEAN_TYPE, null: false # rubocop:disable Graphql/Descriptions
    field :discussion_locked, GraphQL::BOOLEAN_TYPE, # rubocop:disable Graphql/Descriptions
          null: false,
          resolve: -> (obj, _args, _ctx) { !!obj.discussion_locked }

    field :upvotes, GraphQL::INT_TYPE, null: false # rubocop:disable Graphql/Descriptions
    field :downvotes, GraphQL::INT_TYPE, null: false # rubocop:disable Graphql/Descriptions
    field :user_notes_count, GraphQL::INT_TYPE, null: false # rubocop:disable Graphql/Descriptions
    field :web_path, GraphQL::STRING_TYPE, null: false, method: :issue_path # rubocop:disable Graphql/Descriptions
    field :web_url, GraphQL::STRING_TYPE, null: false # rubocop:disable Graphql/Descriptions
    field :relative_position, GraphQL::INT_TYPE, null: true # rubocop:disable Graphql/Descriptions

    field :participants, Types::UserType.connection_type, null: true, complexity: 5, description: 'List of participants for the issue'
    field :time_estimate, GraphQL::INT_TYPE, null: false, description: 'The time estimate on the issue'
    field :total_time_spent, GraphQL::INT_TYPE, null: false, description: 'Total time reported as spent on the issue'

    field :closed_at, Types::TimeType, null: true # rubocop:disable Graphql/Descriptions

    field :created_at, Types::TimeType, null: false # rubocop:disable Graphql/Descriptions
    field :updated_at, Types::TimeType, null: false # rubocop:disable Graphql/Descriptions

    field :task_completion_status, Types::TaskCompletionStatus, null: false # rubocop:disable Graphql/Descriptions
  end
end

Types::IssueType.prepend_if_ee('::EE::Types::IssueType')
