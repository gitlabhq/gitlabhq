# frozen_string_literal: true

module Types
  class MergeRequestType < BaseObject
    graphql_name 'MergeRequest'

    implements(Types::Notes::NoteableType)

    authorize :read_merge_request

    expose_permissions Types::PermissionTypes::MergeRequest

    present_using MergeRequestPresenter

    field :id, GraphQL::ID_TYPE, null: false # rubocop:disable Graphql/Descriptions
    field :iid, GraphQL::STRING_TYPE, null: false # rubocop:disable Graphql/Descriptions
    field :title, GraphQL::STRING_TYPE, null: false # rubocop:disable Graphql/Descriptions
    markdown_field :title_html, null: true
    field :description, GraphQL::STRING_TYPE, null: true # rubocop:disable Graphql/Descriptions
    markdown_field :description_html, null: true
    field :state, MergeRequestStateEnum, null: false # rubocop:disable Graphql/Descriptions
    field :created_at, Types::TimeType, null: false # rubocop:disable Graphql/Descriptions
    field :updated_at, Types::TimeType, null: false # rubocop:disable Graphql/Descriptions
    field :source_project, Types::ProjectType, null: true # rubocop:disable Graphql/Descriptions
    field :target_project, Types::ProjectType, null: false # rubocop:disable Graphql/Descriptions
    field :diff_refs, Types::DiffRefsType, null: true # rubocop:disable Graphql/Descriptions
    # Alias for target_project
    field :project, Types::ProjectType, null: false # rubocop:disable Graphql/Descriptions
    field :project_id, GraphQL::INT_TYPE, null: false, method: :target_project_id # rubocop:disable Graphql/Descriptions
    field :source_project_id, GraphQL::INT_TYPE, null: true # rubocop:disable Graphql/Descriptions
    field :target_project_id, GraphQL::INT_TYPE, null: false # rubocop:disable Graphql/Descriptions
    field :source_branch, GraphQL::STRING_TYPE, null: false # rubocop:disable Graphql/Descriptions
    field :target_branch, GraphQL::STRING_TYPE, null: false # rubocop:disable Graphql/Descriptions
    field :work_in_progress, GraphQL::BOOLEAN_TYPE, method: :work_in_progress?, null: false # rubocop:disable Graphql/Descriptions
    field :merge_when_pipeline_succeeds, GraphQL::BOOLEAN_TYPE, null: true # rubocop:disable Graphql/Descriptions
    field :diff_head_sha, GraphQL::STRING_TYPE, null: true # rubocop:disable Graphql/Descriptions
    field :merge_commit_sha, GraphQL::STRING_TYPE, null: true # rubocop:disable Graphql/Descriptions
    field :user_notes_count, GraphQL::INT_TYPE, null: true # rubocop:disable Graphql/Descriptions
    field :should_remove_source_branch, GraphQL::BOOLEAN_TYPE, method: :should_remove_source_branch?, null: true # rubocop:disable Graphql/Descriptions
    field :force_remove_source_branch, GraphQL::BOOLEAN_TYPE, method: :force_remove_source_branch?, null: true # rubocop:disable Graphql/Descriptions
    field :merge_status, GraphQL::STRING_TYPE, null: true # rubocop:disable Graphql/Descriptions
    field :in_progress_merge_commit_sha, GraphQL::STRING_TYPE, null: true # rubocop:disable Graphql/Descriptions
    field :merge_error, GraphQL::STRING_TYPE, null: true # rubocop:disable Graphql/Descriptions
    field :allow_collaboration, GraphQL::BOOLEAN_TYPE, null: true # rubocop:disable Graphql/Descriptions
    field :should_be_rebased, GraphQL::BOOLEAN_TYPE, method: :should_be_rebased?, null: false # rubocop:disable Graphql/Descriptions
    field :rebase_commit_sha, GraphQL::STRING_TYPE, null: true # rubocop:disable Graphql/Descriptions
    field :rebase_in_progress, GraphQL::BOOLEAN_TYPE, method: :rebase_in_progress?, null: false, calls_gitaly: true # rubocop:disable Graphql/Descriptions
    # rubocop:disable Graphql/Descriptions
    field :merge_commit_message, GraphQL::STRING_TYPE, method: :default_merge_commit_message, null: true, deprecation_reason: "Renamed to defaultMergeCommitMessage"
    # rubocop:enable Graphql/Descriptions
    field :default_merge_commit_message, GraphQL::STRING_TYPE, null: true # rubocop:disable Graphql/Descriptions
    field :merge_ongoing, GraphQL::BOOLEAN_TYPE, method: :merge_ongoing?, null: false # rubocop:disable Graphql/Descriptions
    field :source_branch_exists, GraphQL::BOOLEAN_TYPE, method: :source_branch_exists?, null: false # rubocop:disable Graphql/Descriptions
    field :mergeable_discussions_state, GraphQL::BOOLEAN_TYPE, null: true # rubocop:disable Graphql/Descriptions
    field :web_url, GraphQL::STRING_TYPE, null: true # rubocop:disable Graphql/Descriptions
    field :upvotes, GraphQL::INT_TYPE, null: false # rubocop:disable Graphql/Descriptions
    field :downvotes, GraphQL::INT_TYPE, null: false # rubocop:disable Graphql/Descriptions

    field :head_pipeline, Types::Ci::PipelineType, null: true, method: :actual_head_pipeline # rubocop:disable Graphql/Descriptions
    field :pipelines, Types::Ci::PipelineType.connection_type, # rubocop:disable Graphql/Descriptions
          resolver: Resolvers::MergeRequestPipelinesResolver

    field :milestone, Types::MilestoneType, description: 'The milestone this merge request is linked to',
          null: true,
          resolve: -> (obj, _args, _ctx) { Gitlab::Graphql::Loaders::BatchModelLoader.new(Milestone, obj.milestone_id).find }
    field :assignees, Types::UserType.connection_type, null: true, complexity: 5, description: 'The list of assignees for the merge request'
    field :participants, Types::UserType.connection_type, null: true, complexity: 5, description: 'The list of participants on the merge request'
    field :subscribed, GraphQL::BOOLEAN_TYPE, method: :subscribed?, null: false, complexity: 5,
          description: 'Boolean flag for whether the currently logged in user is subscribed to this MR'
    field :labels, Types::LabelType.connection_type, null: true, complexity: 5, description: 'The list of labels on the merge request'
    field :discussion_locked, GraphQL::BOOLEAN_TYPE, description: 'Boolean flag determining if comments on the merge request are locked to members only',
          null: false,
          resolve: -> (obj, _args, _ctx) { !!obj.discussion_locked }
    field :time_estimate, GraphQL::INT_TYPE, null: false, description: 'The time estimate for the merge request'
    field :total_time_spent, GraphQL::INT_TYPE, null: false, description: 'Total time reported as spent on the merge request'
    field :reference, GraphQL::STRING_TYPE, null: false, method: :to_reference, description: 'Internal merge request reference. Returned in shortened format by default' do
      argument :full, GraphQL::BOOLEAN_TYPE, required: false, default_value: false, description: 'Boolean option specifying whether the reference should be returned in full'
    end
    field :task_completion_status, Types::TaskCompletionStatus, null: false # rubocop:disable Graphql/Descriptions
  end
end
