# frozen_string_literal: true

module Types
  class MergeRequestType < BaseObject
    graphql_name 'MergeRequest'

    connection_type_class Types::MergeRequestConnectionType

    implements Types::Notes::NoteableInterface
    implements Types::CurrentUserTodos
    implements Types::TodoableInterface

    authorize :read_merge_request

    expose_permissions Types::PermissionTypes::MergeRequest

    present_using MergeRequestPresenter

    field :closed_at, Types::TimeType, null: true, complexity: 5,
      description: 'Timestamp of when the merge request was closed, null if not closed.'
    field :created_at, Types::TimeType, null: false,
      description: 'Timestamp of when the merge request was created.'
    field :description, GraphQL::Types::String, null: true,
      description: 'Description of the merge request (Markdown rendered as HTML for caching).'
    field :diff_head_sha, GraphQL::Types::String, null: true, calls_gitaly: true,
      description: 'Diff head SHA of the merge request.'
    field :diff_refs, Types::DiffRefsType, null: true,
      description: 'References of the base SHA, the head SHA, and the start SHA for this merge request.'
    field :diff_stats, [Types::DiffStatsType], null: true, calls_gitaly: true,
      description: 'Details about which files were changed in this merge request.' do
      argument :path, GraphQL::Types::String, required: false, description: 'Specific file path.'
    end
    field :draft, GraphQL::Types::Boolean, method: :draft?, null: false,
      description: 'Indicates if the merge request is a draft.'
    field :id, GraphQL::Types::ID, null: false,
      description: 'ID of the merge request.'
    field :iid, GraphQL::Types::String, null: false,
      description: 'Internal ID of the merge request.'
    field :merge_when_pipeline_succeeds, GraphQL::Types::Boolean, null: true,
      description: 'Indicates if the merge has been set to auto-merge.'
    field :merged_at, Types::TimeType, null: true, complexity: 5,
      description: 'Timestamp of when the merge request was merged, null if not merged.'
    field :project, Types::ProjectType, null: false,
      description: 'Alias for target_project.'
    field :project_id, GraphQL::Types::Int, null: false, method: :target_project_id,
      description: 'ID of the merge request project.'
    field :source_branch, GraphQL::Types::String, null: false,
      description: 'Source branch of the merge request.'
    field :source_branch_protected, GraphQL::Types::Boolean, null: false, calls_gitaly: true,
      description: 'Indicates if the source branch is protected.'
    field :source_project, Types::ProjectType, null: true,
      description: 'Source project of the merge request.'
    field :source_project_id, GraphQL::Types::Int, null: true,
      description: 'ID of the merge request source project.'
    field :state, MergeRequestStateEnum, null: false,
      description: 'State of the merge request.'
    field :target_branch, GraphQL::Types::String, null: false,
      description: 'Target branch of the merge request.'
    field :target_branch_path, GraphQL::Types::String, method: :target_branch_commits_path, null: true,
      calls_gitaly: true,
      description: 'Path to the target branch of the merge request.'
    field :target_project, Types::ProjectType, null: false,
      description: 'Target project of the merge request.'
    field :target_project_id, GraphQL::Types::Int, null: false,
      description: 'ID of the merge request target project.'
    field :title, GraphQL::Types::String, null: false,
      description: 'Title of the merge request.'
    field :updated_at, Types::TimeType, null: false,
      description: 'Timestamp of when the merge request was last updated.'

    field :allow_collaboration, GraphQL::Types::Boolean, null: true,
      description: 'Indicates if members of the target project can push to the fork.'
    field :default_merge_commit_message, GraphQL::Types::String, null: true, calls_gitaly: true,
      description: 'Default merge commit message of the merge request.'
    field :default_squash_commit_message, GraphQL::Types::String, null: true, calls_gitaly: true,
      description: 'Default squash commit message of the merge request.'
    field :diff_stats_summary, Types::DiffStatsSummaryType, null: true, calls_gitaly: true,
      description: 'Summary of which files were changed in this merge request.'
    field :diverged_from_target_branch, GraphQL::Types::Boolean,
      null: false, calls_gitaly: true,
      method: :diverged_from_target_branch?,
      description: 'Indicates if the source branch is behind the target branch.'

    field :downvotes, GraphQL::Types::Int,
      null: false,
      description: 'Number of downvotes for the merge request.',
      resolver: Resolvers::DownVotesCountResolver

    field :force_remove_source_branch, GraphQL::Types::Boolean, method: :force_remove_source_branch?, null: true,
      description: 'Indicates if the project settings will lead to source branch deletion after merge.'
    field :in_progress_merge_commit_sha, GraphQL::Types::String, null: true,
      description: 'Commit SHA of the merge request if merge is in progress.'
    field :merge_commit_sha, GraphQL::Types::String, null: true,
      description: 'SHA of the merge request commit (set once merged).'
    field :merge_error, GraphQL::Types::String, null: true,
      description: 'Error message due to a merge error.'
    field :merge_ongoing, GraphQL::Types::Boolean, method: :merge_ongoing?, null: false,
      description: 'Indicates if a merge is currently occurring.'
    field :merge_status, GraphQL::Types::String, method: :public_merge_status, null: true,
      description: 'Status of the merge request.',
      deprecated: { reason: :renamed, replacement: 'MergeRequest.mergeStatusEnum', milestone: '14.0' }
    field :merge_status_enum, ::Types::MergeRequests::MergeStatusEnum,
      method: :public_merge_status, null: true,
      description: 'Merge status of the merge request.'

    field :merge_after, ::Types::TimeType,
      null: true,
      description: 'Date after which the merge request can be merged.'

    field :detailed_merge_status, ::Types::MergeRequests::DetailedMergeStatusEnum, null: true,
      calls_gitaly: true,
      description: 'Detailed merge status of the merge request.'

    field :mergeability_checks, [::Types::MergeRequests::MergeabilityCheckType],
      null: false,
      description: 'Status of all mergeability checks of the merge request.',
      method: :all_mergeability_checks_results,
      experiment: { milestone: '16.5' },
      calls_gitaly: true

    field :mergeable_discussions_state, GraphQL::Types::Boolean, null: true, calls_gitaly: true,
      description: 'Indicates if all discussions in the merge request have been resolved, ' \
        'allowing the merge request to be merged.'
    field :rebase_commit_sha, GraphQL::Types::String, null: true,
      description: 'Rebase commit SHA of the merge request.'
    field :rebase_in_progress, GraphQL::Types::Boolean, method: :rebase_in_progress?, null: false, calls_gitaly: true,
      description: 'Indicates if there is a rebase currently in progress for the merge request.'
    field :should_be_rebased, GraphQL::Types::Boolean, method: :should_be_rebased?, null: false, calls_gitaly: true,
      description: 'Indicates if the merge request will be rebased.'
    field :should_remove_source_branch, GraphQL::Types::Boolean, method: :should_remove_source_branch?, null: true,
      description: 'Indicates if the source branch of the merge request will be deleted after merge.'
    field :source_branch_exists, GraphQL::Types::Boolean,
      null: false, calls_gitaly: true,
      method: :source_branch_exists?,
      description: 'Indicates if the source branch of the merge request exists.'
    field :target_branch_exists, GraphQL::Types::Boolean,
      null: false, calls_gitaly: true,
      method: :target_branch_exists?,
      description: 'Indicates if the target branch of the merge request exists.'

    field :upvotes, GraphQL::Types::Int,
      null: false,
      description: 'Number of upvotes for the merge request.',
      resolver: Resolvers::UpVotesCountResolver

    field :resolvable_discussions_count, GraphQL::Types::Int, null: true,
      description: 'Number of user discussions that are resolvable in the merge request.'
    field :resolved_discussions_count, GraphQL::Types::Int, null: true,
      description: 'Number of user discussions that are resolved in the merge request.'
    field :user_discussions_count, GraphQL::Types::Int, null: true,
      description: 'Number of user discussions in the merge request.',
      resolver: Resolvers::UserDiscussionsCountResolver
    field :user_notes_count, GraphQL::Types::Int, null: true,
      description: 'User notes count of the merge request.',
      resolver: Resolvers::UserNotesCountResolver

    field :web_path,
      GraphQL::Types::String,
      null: false,
      description: 'Web path of the merge request.'

    field :web_url, GraphQL::Types::String, null: true,
      description: 'Web URL of the merge request.'

    field :head_pipeline, Types::Ci::PipelineType, null: true, method: :diff_head_pipeline,
      description: 'Pipeline running on the branch HEAD of the merge request.'
    field :pipelines,
      null: true,
      description: 'Pipelines for the merge request. Note: for performance reasons, ' \
        'no more than the most recent 500 pipelines will be returned.',
      resolver: Resolvers::MergeRequestPipelinesResolver

    field :assignees,
      type: Types::MergeRequests::AssigneeType.connection_type,
      null: true,
      complexity: 5,
      description: 'Assignees of the merge request.'
    field :author, Types::MergeRequests::AuthorType, null: true,
      description: 'User who created this merge request.'
    field :discussion_locked, GraphQL::Types::Boolean,
      description: 'Indicates if comments on the merge request are locked to members only.',
      null: false
    field :human_time_estimate, GraphQL::Types::String, null: true,
      description: 'Human-readable time estimate of the merge request.'
    field :human_total_time_spent, GraphQL::Types::String, null: true,
      description: 'Human-readable total time reported as spent on the merge request.'
    field :labels, Types::LabelType.connection_type,
      null: true, complexity: 5,
      description: 'Labels of the merge request.',
      resolver: Resolvers::BulkLabelsResolver

    field :auto_merge_enabled, GraphQL::Types::Boolean, null: false,
      description: 'Indicates if auto merge is enabled for the merge request.'
    field :commit_count, GraphQL::Types::Int, null: true, method: :commits_count,
      description: 'Number of commits in the merge request.'
    field :conflicts, GraphQL::Types::Boolean, null: false, method: :cannot_be_merged?,
      description: 'Indicates if the merge request has conflicts.'
    field :milestone, Types::MilestoneType, null: true,
      description: 'Milestone of the merge request.'
    field :participants,
      Types::MergeRequests::ParticipantType.connection_type,
      null: true,
      complexity: 15,
      description: 'Participants in the merge request. This includes the author, ' \
        'assignees, reviewers, and users mentioned in notes.',
      resolver: Resolvers::Users::ParticipantsResolver
    field :reference, GraphQL::Types::String, null: false, method: :to_reference,
      description: 'Internal reference of the merge request. Returned in shortened format by default.' do
      argument :full, GraphQL::Types::Boolean, required: false, default_value: false,
        description: 'Boolean option specifying whether the reference should be returned in full.'
    end
    field :reviewers,
      type: Types::MergeRequests::ReviewerType.connection_type,
      null: true,
      complexity: 5,
      description: 'Users from whom a review has been requested.'
    field :subscribed, GraphQL::Types::Boolean, method: :subscribed?, null: false, complexity: 5,
      description: 'Indicates if the currently logged in user is subscribed to this merge request.'
    field :supports_lock_on_merge, GraphQL::Types::Boolean, null: false, method: :supports_lock_on_merge?,
      description: 'Indicates if the merge request supports locked labels.'
    field :task_completion_status, Types::TaskCompletionStatus, null: false,
      description: Types::TaskCompletionStatus.description
    field :time_estimate, GraphQL::Types::Int, null: false,
      description: 'Time estimate of the merge request.'
    field :total_time_spent, GraphQL::Types::Int, null: false,
      description: 'Total time (in seconds) reported as spent on the merge request.'

    field :approved, GraphQL::Types::Boolean,
      method: :approved?,
      null: false, calls_gitaly: true,
      description: 'Indicates if the merge request has all the required approvals.'

    field :approved_by, Types::UserType.connection_type, null: true,
      description: 'Users who approved the merge request.', method: :approved_by_users
    field :auto_merge_strategy, GraphQL::Types::String, null: true,
      description: 'Selected auto merge strategy.'
    field :available_auto_merge_strategies, [GraphQL::Types::String], null: true, calls_gitaly: true,
      description: 'Array of available auto merge strategies.'
    field :commits, Types::Repositories::CommitType.connection_type, null: true,
      calls_gitaly: true, description: 'Merge request commits.'
    field :commits_without_merge_commits, Types::Repositories::CommitType.connection_type, null: true,
      calls_gitaly: true, description: 'Merge request commits excluding merge commits.'
    field :committers, Types::UserType.connection_type, null: true, complexity: 5,
      calls_gitaly: true, description: 'Users who have added commits to the merge request.'
    field :has_ci, GraphQL::Types::Boolean, null: false, method: :has_ci?,
      description: 'Indicates if the merge request has CI.'
    field :merge_user, Types::UserType, null: true,
      description: 'User who merged this merge request or set it to auto-merge.'
    field :mergeable, GraphQL::Types::Boolean, null: false, method: :mergeable?, calls_gitaly: true,
      description: 'Indicates if the merge request is mergeable.'
    field :security_auto_fix,
      GraphQL::Types::Boolean,
      null: true,
      description: 'Indicates if the merge request is created by @GitLab-Security-Bot.',
      deprecated: {
        reason: 'Security Auto Fix experiment feature was removed. ' \
          'It was always hidden behind `security_auto_fix` feature flag',
        milestone: '16.11'
      }

    field :squash, GraphQL::Types::Boolean, null: false,
      description: <<~HEREDOC.squish
                   Indicates if the merge request is set to be squashed when merged.
                   [Project settings](https://docs.gitlab.com/ee/user/project/merge_requests/squash_and_merge.html#configure-squash-options-for-a-project)
                   may override this value. Use `squash_on_merge` instead to take project squash options into account.
      HEREDOC
    field :squash_on_merge, GraphQL::Types::Boolean, null: false, method: :squash_on_merge?,
      description: 'Indicates if the merge request will be squashed when merged.'
    field :timelogs, Types::TimelogType.connection_type, null: false,
      description: 'Timelogs on the merge request.'

    field :award_emoji, Types::AwardEmojis::AwardEmojiType.connection_type,
      null: true,
      description: 'List of emoji reactions associated with the merge request.'

    field :codequality_reports_comparer,
      type: ::Types::Security::CodequalityReportsComparerType,
      null: true,
      description: 'Code quality reports comparison reported on the merge request.',
      resolver: ::Resolvers::CodequalityReportsComparerResolver

    field :prepared_at, Types::TimeType, null: true,
      description: 'Timestamp of when the merge request was prepared.'

    field :allows_multiple_assignees,
      GraphQL::Types::Boolean,
      method: :allows_multiple_assignees?,
      description: 'Allows assigning multiple users to a merge request.',
      null: false

    field :allows_multiple_reviewers,
      GraphQL::Types::Boolean,
      method: :allows_multiple_reviewers?,
      description: 'Allows assigning multiple reviewers to a merge request.',
      null: false

    field :retargeted, GraphQL::Types::Boolean, null: true,
      description: 'Indicates if merge request was retargeted.'

    field :hidden, GraphQL::Types::Boolean, null: true,
      description: 'Indicates the merge request is hidden because the author has been banned.', method: :hidden?

    markdown_field :title_html, null: true
    markdown_field :description_html, null: true

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

    def default_merge_commit_message
      object.default_merge_commit_message(include_description: false, user: current_user)
    end

    def default_squash_commit_message
      object.default_squash_commit_message(user: current_user)
    end

    def available_auto_merge_strategies
      AutoMergeService.new(object.project, current_user).available_strategies(object)
    end

    def closed_at
      object.metrics&.latest_closed_at
    end

    def commits
      object.commits.commits
    end

    def commits_without_merge_commits
      object.commits.without_merge_commits
    end

    def security_auto_fix
      object.author == ::Users::Internal.security_bot
    end

    def merge_user
      object.metrics&.merged_by || object.merge_user
    end

    def merge_after
      object.merge_schedule&.merge_after
    end

    def detailed_merge_status
      ::MergeRequests::Mergeability::DetailedMergeStatusService.new(merge_request: object).execute
    end

    # This is temporary to fix a bug where `committers` is already loaded and memoized
    # and calling it again with a certain GraphQL query can cause the Rails to to throw
    # a ActiveRecord::ImmutableRelation error
    def committers
      object.commits.committers
    end

    def web_path
      ::Gitlab::Routing.url_helpers.project_merge_request_path(object.project, object)
    end

    def resolvable_discussions_count
      notes_count_for_collection(:merge_request_resolvable_discussions_count, &:resolvable)
    end

    def resolved_discussions_count
      notes_count_for_collection(:merge_request_resolved_discussions_count, &:resolved)
    end

    def notes_count_for_collection(key)
      BatchLoader::GraphQL.for(object.id).batch(key: key) do |ids, loader, args|
        counts = Note.count_for_collection(
          ids,
          'MergeRequest',
          'COUNT(DISTINCT discussion_id) as count'
        )
        counts = yield(counts).index_by(&:noteable_id)

        ids.each do |id|
          loader.call(id, counts[id]&.count || 0)
        end
      end
    end
  end
end

Types::MergeRequestType.prepend_mod_with('Types::MergeRequestType')
