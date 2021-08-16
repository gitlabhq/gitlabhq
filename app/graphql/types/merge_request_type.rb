# frozen_string_literal: true

module Types
  class MergeRequestType < BaseObject
    graphql_name 'MergeRequest'

    connection_type_class(Types::MergeRequestConnectionType)

    implements(Types::Notes::NoteableInterface)
    implements(Types::CurrentUserTodos)

    authorize :read_merge_request

    expose_permissions Types::PermissionTypes::MergeRequest

    present_using MergeRequestPresenter

    field :id, GraphQL::Types::ID, null: false,
          description: 'ID of the merge request.'
    field :iid, GraphQL::Types::String, null: false,
          description: 'Internal ID of the merge request.'
    field :title, GraphQL::Types::String, null: false,
          description: 'Title of the merge request.'
    markdown_field :title_html, null: true
    field :description, GraphQL::Types::String, null: true,
          description: 'Description of the merge request (Markdown rendered as HTML for caching).'
    markdown_field :description_html, null: true
    field :state, MergeRequestStateEnum, null: false,
          description: 'State of the merge request.'
    field :created_at, Types::TimeType, null: false,
          description: 'Timestamp of when the merge request was created.'
    field :updated_at, Types::TimeType, null: false,
          description: 'Timestamp of when the merge request was last updated.'
    field :merged_at, Types::TimeType, null: true, complexity: 5,
          description: 'Timestamp of when the merge request was merged, null if not merged.'
    field :source_project, Types::ProjectType, null: true,
          description: 'Source project of the merge request.'
    field :target_project, Types::ProjectType, null: false,
          description: 'Target project of the merge request.'
    field :diff_refs, Types::DiffRefsType, null: true,
          description: 'References of the base SHA, the head SHA, and the start SHA for this merge request.'
    field :project, Types::ProjectType, null: false,
          description: 'Alias for target_project.'
    field :project_id, GraphQL::Types::Int, null: false, method: :target_project_id,
          description: 'ID of the merge request project.'
    field :source_project_id, GraphQL::Types::Int, null: true,
          description: 'ID of the merge request source project.'
    field :target_project_id, GraphQL::Types::Int, null: false,
          description: 'ID of the merge request target project.'
    field :source_branch, GraphQL::Types::String, null: false,
          description: 'Source branch of the merge request.'
    field :source_branch_protected, GraphQL::Types::Boolean, null: false, calls_gitaly: true,
          description: 'Indicates if the source branch is protected.'
    field :target_branch, GraphQL::Types::String, null: false,
          description: 'Target branch of the merge request.'
    field :work_in_progress, GraphQL::Types::Boolean, method: :work_in_progress?, null: false,
          deprecated: { reason: 'Use `draft`', milestone: '13.12' },
          description: 'Indicates if the merge request is a draft.'
    field :draft, GraphQL::Types::Boolean, method: :draft?, null: false,
          description: 'Indicates if the merge request is a draft.'
    field :merge_when_pipeline_succeeds, GraphQL::Types::Boolean, null: true,
          description: 'Indicates if the merge has been set to be merged when its pipeline succeeds (MWPS).'
    field :diff_head_sha, GraphQL::Types::String, null: true,
          description: 'Diff head SHA of the merge request.'
    field :diff_stats, [Types::DiffStatsType], null: true, calls_gitaly: true,
          description: 'Details about which files were changed in this merge request.' do
      argument :path, GraphQL::Types::String, required: false, description: 'A specific file-path.'
    end

    field :diff_stats_summary, Types::DiffStatsSummaryType, null: true, calls_gitaly: true,
          description: 'Summary of which files were changed in this merge request.'
    field :merge_commit_sha, GraphQL::Types::String, null: true,
          description: 'SHA of the merge request commit (set once merged).'
    field :user_notes_count, GraphQL::Types::Int, null: true,
          description: 'User notes count of the merge request.',
          resolver: Resolvers::UserNotesCountResolver
    field :user_discussions_count, GraphQL::Types::Int, null: true,
          description: 'Number of user discussions in the merge request.',
          resolver: Resolvers::UserDiscussionsCountResolver
    field :should_remove_source_branch, GraphQL::Types::Boolean, method: :should_remove_source_branch?, null: true,
          description: 'Indicates if the source branch of the merge request will be deleted after merge.'
    field :force_remove_source_branch, GraphQL::Types::Boolean, method: :force_remove_source_branch?, null: true,
          description: 'Indicates if the project settings will lead to source branch deletion after merge.'
    field :merge_status, GraphQL::Types::String, method: :public_merge_status, null: true,
          description: 'Status of the merge request.',
          deprecated: { reason: :renamed, replacement: 'MergeRequest.mergeStatusEnum', milestone: '14.0' }
    field :merge_status_enum, ::Types::MergeRequests::MergeStatusEnum,
          method: :public_merge_status, null: true,
          description: 'Merge status of the merge request.'
    field :in_progress_merge_commit_sha, GraphQL::Types::String, null: true,
          description: 'Commit SHA of the merge request if merge is in progress.'
    field :merge_error, GraphQL::Types::String, null: true,
          description: 'Error message due to a merge error.'
    field :allow_collaboration, GraphQL::Types::Boolean, null: true,
          description: 'Indicates if members of the target project can push to the fork.'
    field :should_be_rebased, GraphQL::Types::Boolean, method: :should_be_rebased?, null: false, calls_gitaly: true,
          description: 'Indicates if the merge request will be rebased.'
    field :rebase_commit_sha, GraphQL::Types::String, null: true,
          description: 'Rebase commit SHA of the merge request.'
    field :rebase_in_progress, GraphQL::Types::Boolean, method: :rebase_in_progress?, null: false, calls_gitaly: true,
          description: 'Indicates if there is a rebase currently in progress for the merge request.'
    field :default_merge_commit_message, GraphQL::Types::String, null: true,
          description: 'Default merge commit message of the merge request.'
    field :default_merge_commit_message_with_description, GraphQL::Types::String, null: true,
          description: 'Default merge commit message of the merge request with description.'
    field :default_squash_commit_message, GraphQL::Types::String, null: true, calls_gitaly: true,
          description: 'Default squash commit message of the merge request.'
    field :merge_ongoing, GraphQL::Types::Boolean, method: :merge_ongoing?, null: false,
          description: 'Indicates if a merge is currently occurring.'
    field :source_branch_exists, GraphQL::Types::Boolean,
          null: false, calls_gitaly: true,
          method: :source_branch_exists?,
          description: 'Indicates if the source branch of the merge request exists.'
    field :target_branch_exists, GraphQL::Types::Boolean,
          null: false, calls_gitaly: true,
          method: :target_branch_exists?,
          description: 'Indicates if the target branch of the merge request exists.'
    field :diverged_from_target_branch, GraphQL::Types::Boolean,
          null: false, calls_gitaly: true,
          method: :diverged_from_target_branch?,
          description: 'Indicates if the source branch is behind the target branch.'
    field :mergeable_discussions_state, GraphQL::Types::Boolean, null: true,
          description: 'Indicates if all discussions in the merge request have been resolved, allowing the merge request to be merged.'
    field :web_url, GraphQL::Types::String, null: true,
          description: 'Web URL of the merge request.'
    field :upvotes, GraphQL::Types::Int, null: false,
          description: 'Number of upvotes for the merge request.'
    field :downvotes, GraphQL::Types::Int, null: false,
          description: 'Number of downvotes for the merge request.'

    field :head_pipeline, Types::Ci::PipelineType, null: true, method: :actual_head_pipeline,
          description: 'The pipeline running on the branch HEAD of the merge request.'
    field :pipelines,
          null: true,
          description: 'Pipelines for the merge request. Note: for performance reasons, no more than the most recent 500 pipelines will be returned.',
          resolver: Resolvers::MergeRequestPipelinesResolver

    field :milestone, Types::MilestoneType, null: true,
          description: 'The milestone of the merge request.'
    field :assignees,
          type: Types::MergeRequests::AssigneeType.connection_type,
          null: true,
          complexity: 5,
          description: 'Assignees of the merge request.'
    field :reviewers,
          type: Types::MergeRequests::ReviewerType.connection_type,
          null: true,
          complexity: 5,
          description: 'Users from whom a review has been requested.'
    field :author, Types::UserType, null: true,
          description: 'User who created this merge request.'
    field :participants, Types::UserType.connection_type, null: true, complexity: 15,
          description: 'Participants in the merge request. This includes the author, assignees, reviewers, and users mentioned in notes.'
    field :subscribed, GraphQL::Types::Boolean, method: :subscribed?, null: false, complexity: 5,
          description: 'Indicates if the currently logged in user is subscribed to this merge request.'
    field :labels, Types::LabelType.connection_type, null: true, complexity: 5,
          description: 'Labels of the merge request.'
    field :discussion_locked, GraphQL::Types::Boolean,
          description: 'Indicates if comments on the merge request are locked to members only.',
          null: false
    field :time_estimate, GraphQL::Types::Int, null: false,
          description: 'Time estimate of the merge request.'
    field :total_time_spent, GraphQL::Types::Int, null: false,
          description: 'Total time reported as spent on the merge request.'
    field :human_time_estimate, GraphQL::Types::String, null: true,
          description: 'Human-readable time estimate of the merge request.'
    field :human_total_time_spent, GraphQL::Types::String, null: true,
          description: 'Human-readable total time reported as spent on the merge request.'
    field :reference, GraphQL::Types::String, null: false, method: :to_reference,
          description: 'Internal reference of the merge request. Returned in shortened format by default.' do
      argument :full, GraphQL::Types::Boolean, required: false, default_value: false,
               description: 'Boolean option specifying whether the reference should be returned in full.'
    end
    field :task_completion_status, Types::TaskCompletionStatus, null: false,
          description: Types::TaskCompletionStatus.description
    field :commit_count, GraphQL::Types::Int, null: true, method: :commits_count,
          description: 'Number of commits in the merge request.'
    field :conflicts, GraphQL::Types::Boolean, null: false, method: :cannot_be_merged?,
          description: 'Indicates if the merge request has conflicts.'
    field :auto_merge_enabled, GraphQL::Types::Boolean, null: false,
          description: 'Indicates if auto merge is enabled for the merge request.'

    field :approved_by, Types::UserType.connection_type, null: true,
          description: 'Users who approved the merge request.'
    field :squash_on_merge, GraphQL::Types::Boolean, null: false, method: :squash_on_merge?,
          description: 'Indicates if squash on merge is enabled.'
    field :squash, GraphQL::Types::Boolean, null: false,
          description: 'Indicates if squash on merge is enabled.'
    field :available_auto_merge_strategies, [GraphQL::Types::String], null: true, calls_gitaly: true,
          description: 'Array of available auto merge strategies.'
    field :has_ci, GraphQL::Types::Boolean, null: false, method: :has_ci?,
          description: 'Indicates if the merge request has CI.'
    field :mergeable, GraphQL::Types::Boolean, null: false, method: :mergeable?, calls_gitaly: true,
          description: 'Indicates if the merge request is mergeable.'
    field :commits_without_merge_commits, Types::CommitType.connection_type, null: true,
          calls_gitaly: true, description: 'Merge request commits excluding merge commits.'
    field :security_auto_fix, GraphQL::Types::Boolean, null: true,
          description: 'Indicates if the merge request is created by @GitLab-Security-Bot.'
    field :auto_merge_strategy, GraphQL::Types::String, null: true,
          description: 'Selected auto merge strategy.'
    field :merge_user, Types::UserType, null: true,
          description: 'User who merged this merge request.'
    field :timelogs, Types::TimelogType.connection_type, null: false,
          description: 'Timelogs on the merge request.'

    def approved_by
      object.approved_by_users
    end

    def user_notes_count
      BatchLoader::GraphQL.for(object.id).batch(key: :merge_request_user_notes_count) do |ids, loader, args|
        counts = Note.count_for_collection(ids, 'MergeRequest').index_by(&:noteable_id)

        ids.each do |id|
          loader.call(id, counts[id]&.count || 0)
        end
      end
    end

    def user_discussions_count
      BatchLoader::GraphQL.for(object.id).batch(key: :merge_request_user_discussions_count) do |ids, loader, args|
        counts = Note.count_for_collection(ids, 'MergeRequest', 'COUNT(DISTINCT discussion_id) as count').index_by(&:noteable_id)

        ids.each do |id|
          loader.call(id, counts[id]&.count || 0)
        end
      end
    end

    def diff_stats(path: nil)
      stats = Array.wrap(object.diff_stats&.to_a)

      if path.present?
        stats.select { |s| s.path == path }
      else
        stats
      end
    end

    def diff_stats_summary
      BatchLoaders::MergeRequestDiffSummaryBatchLoader.load_for(object)
    end

    def source_branch_protected
      object.source_project.present? && ProtectedBranch.protected?(object.source_project, object.source_branch)
    end

    def discussion_locked
      !!object.discussion_locked
    end

    def default_merge_commit_message_with_description
      object.default_merge_commit_message(include_description: true)
    end

    def available_auto_merge_strategies
      AutoMergeService.new(object.project, current_user).available_strategies(object)
    end

    def commits_without_merge_commits
      object.recent_commits.without_merge_commits
    end

    def security_auto_fix
      object.author == User.security_bot
    end

    def reviewers
      object.reviewers
    end
  end
end

Types::MergeRequestType.prepend_mod_with('Types::MergeRequestType')
