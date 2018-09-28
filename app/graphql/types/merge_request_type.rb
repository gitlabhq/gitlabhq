# frozen_string_literal: true

module Types
  class MergeRequestType < BaseObject
    expose_permissions Types::PermissionTypes::MergeRequest

    present_using MergeRequestPresenter

    graphql_name 'MergeRequest'

    field :id, GraphQL::ID_TYPE, null: false
    field :iid, GraphQL::ID_TYPE, null: false
    field :title, GraphQL::STRING_TYPE, null: false
    field :description, GraphQL::STRING_TYPE, null: true
    field :state, GraphQL::STRING_TYPE, null: true
    field :created_at, Types::TimeType, null: false
    field :updated_at, Types::TimeType, null: false
    field :source_project, Types::ProjectType, null: true
    field :target_project, Types::ProjectType, null: false
    # Alias for target_project
    field :project, Types::ProjectType, null: false
    field :project_id, GraphQL::INT_TYPE, null: false, method: :target_project_id
    field :source_project_id, GraphQL::INT_TYPE, null: true
    field :target_project_id, GraphQL::INT_TYPE, null: false
    field :source_branch, GraphQL::STRING_TYPE, null: false
    field :target_branch, GraphQL::STRING_TYPE, null: false
    field :work_in_progress, GraphQL::BOOLEAN_TYPE, method: :work_in_progress?, null: false
    field :merge_when_pipeline_succeeds, GraphQL::BOOLEAN_TYPE, null: true
    field :diff_head_sha, GraphQL::STRING_TYPE, null: true
    field :merge_commit_sha, GraphQL::STRING_TYPE, null: true
    field :user_notes_count, GraphQL::INT_TYPE, null: true
    field :should_remove_source_branch, GraphQL::BOOLEAN_TYPE, method: :should_remove_source_branch?, null: true
    field :force_remove_source_branch, GraphQL::BOOLEAN_TYPE, method: :force_remove_source_branch?, null: true
    field :merge_status, GraphQL::STRING_TYPE, null: true
    field :in_progress_merge_commit_sha, GraphQL::STRING_TYPE, null: true
    field :merge_error, GraphQL::STRING_TYPE, null: true
    field :allow_collaboration, GraphQL::BOOLEAN_TYPE, null: true
    field :should_be_rebased, GraphQL::BOOLEAN_TYPE, method: :should_be_rebased?, null: false
    field :rebase_commit_sha, GraphQL::STRING_TYPE, null: true
    field :rebase_in_progress, GraphQL::BOOLEAN_TYPE, method: :rebase_in_progress?, null: false
    field :diff_head_sha, GraphQL::STRING_TYPE, null: true
    field :merge_commit_message, GraphQL::STRING_TYPE, null: true
    field :merge_ongoing, GraphQL::BOOLEAN_TYPE, method: :merge_ongoing?, null: false
    field :source_branch_exists, GraphQL::BOOLEAN_TYPE, method: :source_branch_exists?, null: false
    field :mergeable_discussions_state, GraphQL::BOOLEAN_TYPE, null: true
    field :web_url, GraphQL::STRING_TYPE, null: true
    field :upvotes, GraphQL::INT_TYPE, null: false
    field :downvotes, GraphQL::INT_TYPE, null: false
    field :subscribed, GraphQL::BOOLEAN_TYPE, method: :subscribed?, null: false

    field :head_pipeline, Types::Ci::PipelineType, null: true, method: :actual_head_pipeline do
      authorize :read_pipeline
    end
    field :pipelines, Types::Ci::PipelineType.connection_type,
          resolver: Resolvers::MergeRequestPipelinesResolver
  end
end
