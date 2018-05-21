Types::MergeRequestType = GraphQL::ObjectType.define do
  present_using MergeRequestPresenter

  name 'MergeRequest'

  field :id, !types.ID
  field :iid, !types.ID
  field :title, !types.String
  field :description, types.String
  field :state, types.String
  field :created_at, !Types::TimeType
  field :updated_at, !Types::TimeType
  field :source_project, Types::ProjectType
  field :target_project, !Types::ProjectType
  # Alias for target_project
  field :project, !Types::ProjectType
  field :project_id, !types.Int, property: :target_project_id
  field :source_project_id, types.Int
  field :target_project_id, !types.Int
  field :source_branch, !types.String
  field :target_branch, !types.String
  field :work_in_progress, types.Boolean, property: :work_in_progress?
  field :merge_when_pipeline_succeeds, types.Boolean
  field :sha, types.String, property: :diff_head_sha
  field :merge_commit_sha, types.String
  field :user_notes_count, types.Int
  field :should_remove_source_branch, types.Boolean, property: :should_remove_source_branch?
  field :force_remove_source_branch, types.Boolean, property: :force_remove_source_branch?
  field :merge_status, types.String
  field :in_progress_merge_commit_sha, types.String
  field :merge_error, types.String
  field :allow_maintainer_to_push, types.Boolean
  field :should_be_rebased, types.Boolean, property: :should_be_rebased?
  field :rebase_commit_sha, types.String
  field :rebase_in_progress, types.Boolean, property: :rebase_in_progress?
  field :diff_head_sha, types.String
  field :merge_commit_message, types.String
  field :merge_ongoing, types.Boolean, property: :merge_ongoing?
  field :work_in_progress, types.Boolean, property: :work_in_progress?
  field :source_branch_exists, types.Boolean, property: :source_branch_exists?
  field :mergeable_discussions_state, types.Boolean
  field :web_url, types.String, property: :web_url
  field :upvotes, types.Int
  field :downvotes, types.Int
  field :subscribed, types.Boolean, property: :subscribed?
end
