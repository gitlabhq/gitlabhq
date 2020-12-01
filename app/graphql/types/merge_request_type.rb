# frozen_string_literal: true

module Types
  class MergeRequestType < BaseObject
    graphql_name 'MergeRequest'

    connection_type_class(Types::CountableConnectionType)

    implements(Types::Notes::NoteableType)
    implements(Types::CurrentUserTodos)

    authorize :read_merge_request

    expose_permissions Types::PermissionTypes::MergeRequest

    present_using MergeRequestPresenter

    field :id, GraphQL::ID_TYPE, null: false,
          description: 'ID of the merge request'
    field :iid, GraphQL::STRING_TYPE, null: false,
          description: 'Internal ID of the merge request'
    field :title, GraphQL::STRING_TYPE, null: false,
          description: 'Title of the merge request'
    markdown_field :title_html, null: true
    field :description, GraphQL::STRING_TYPE, null: true,
          description: 'Description of the merge request (Markdown rendered as HTML for caching)'
    markdown_field :description_html, null: true
    field :state, MergeRequestStateEnum, null: false,
          description: 'State of the merge request'
    field :created_at, Types::TimeType, null: false,
          description: 'Timestamp of when the merge request was created'
    field :updated_at, Types::TimeType, null: false,
          description: 'Timestamp of when the merge request was last updated'
    field :merged_at, Types::TimeType, null: true, complexity: 5,
          description: 'Timestamp of when the merge request was merged, null if not merged'
    field :source_project, Types::ProjectType, null: true,
          description: 'Source project of the merge request'
    field :target_project, Types::ProjectType, null: false,
          description: 'Target project of the merge request'
    field :diff_refs, Types::DiffRefsType, null: true,
          description: 'References of the base SHA, the head SHA, and the start SHA for this merge request'
    field :project, Types::ProjectType, null: false,
          description: 'Alias for target_project'
    field :project_id, GraphQL::INT_TYPE, null: false, method: :target_project_id,
          description: 'ID of the merge request project'
    field :source_project_id, GraphQL::INT_TYPE, null: true,
          description: 'ID of the merge request source project'
    field :target_project_id, GraphQL::INT_TYPE, null: false,
          description: 'ID of the merge request target project'
    field :source_branch, GraphQL::STRING_TYPE, null: false,
          description: 'Source branch of the merge request'
    field :source_branch_protected, GraphQL::BOOLEAN_TYPE, null: false, calls_gitaly: true,
          description: 'Indicates if the source branch is protected'
    field :target_branch, GraphQL::STRING_TYPE, null: false,
          description: 'Target branch of the merge request'
    field :work_in_progress, GraphQL::BOOLEAN_TYPE, method: :work_in_progress?, null: false,
          description: 'Indicates if the merge request is a work in progress (WIP)'
    field :merge_when_pipeline_succeeds, GraphQL::BOOLEAN_TYPE, null: true,
          description: 'Indicates if the merge has been set to be merged when its pipeline succeeds (MWPS)'
    field :diff_head_sha, GraphQL::STRING_TYPE, null: true,
          description: 'Diff head SHA of the merge request'
    field :diff_stats, [Types::DiffStatsType], null: true, calls_gitaly: true,
          description: 'Details about which files were changed in this merge request' do
      argument :path, GraphQL::STRING_TYPE, required: false, description: 'A specific file-path'
    end

    field :diff_stats_summary, Types::DiffStatsSummaryType, null: true, calls_gitaly: true,
          description: 'Summary of which files were changed in this merge request'
    field :merge_commit_sha, GraphQL::STRING_TYPE, null: true,
          description: 'SHA of the merge request commit (set once merged)'
    field :user_notes_count, GraphQL::INT_TYPE, null: true,
          description: 'User notes count of the merge request'
    field :user_discussions_count, GraphQL::INT_TYPE, null: true,
          description: 'Number of user discussions in the merge request'
    field :should_remove_source_branch, GraphQL::BOOLEAN_TYPE, method: :should_remove_source_branch?, null: true,
          description: 'Indicates if the source branch of the merge request will be deleted after merge'
    field :force_remove_source_branch, GraphQL::BOOLEAN_TYPE, method: :force_remove_source_branch?, null: true,
          description: 'Indicates if the project settings will lead to source branch deletion after merge'
    field :merge_status, GraphQL::STRING_TYPE, method: :public_merge_status, null: true,
          description: 'Status of the merge request'
    field :in_progress_merge_commit_sha, GraphQL::STRING_TYPE, null: true,
          description: 'Commit SHA of the merge request if merge is in progress'
    field :merge_error, GraphQL::STRING_TYPE, null: true,
          description: 'Error message due to a merge error'
    field :allow_collaboration, GraphQL::BOOLEAN_TYPE, null: true,
          description: 'Indicates if members of the target project can push to the fork'
    field :should_be_rebased, GraphQL::BOOLEAN_TYPE, method: :should_be_rebased?, null: false, calls_gitaly: true,
          description: 'Indicates if the merge request will be rebased'
    field :rebase_commit_sha, GraphQL::STRING_TYPE, null: true,
          description: 'Rebase commit SHA of the merge request'
    field :rebase_in_progress, GraphQL::BOOLEAN_TYPE, method: :rebase_in_progress?, null: false, calls_gitaly: true,
          description: 'Indicates if there is a rebase currently in progress for the merge request'
    field :default_merge_commit_message, GraphQL::STRING_TYPE, null: true,
          description: 'Default merge commit message of the merge request'
    field :merge_ongoing, GraphQL::BOOLEAN_TYPE, method: :merge_ongoing?, null: false,
          description: 'Indicates if a merge is currently occurring'
    field :source_branch_exists, GraphQL::BOOLEAN_TYPE,
          null: false, calls_gitaly: true,
          method: :source_branch_exists?,
          description: 'Indicates if the source branch of the merge request exists'
    field :target_branch_exists, GraphQL::BOOLEAN_TYPE,
          null: false, calls_gitaly: true,
          method: :target_branch_exists?,
          description: 'Indicates if the target branch of the merge request exists'
    field :mergeable_discussions_state, GraphQL::BOOLEAN_TYPE, null: true,
          description: 'Indicates if all discussions in the merge request have been resolved, allowing the merge request to be merged'
    field :web_url, GraphQL::STRING_TYPE, null: true,
          description: 'Web URL of the merge request'
    field :upvotes, GraphQL::INT_TYPE, null: false,
          description: 'Number of upvotes for the merge request'
    field :downvotes, GraphQL::INT_TYPE, null: false,
          description: 'Number of downvotes for the merge request'

    field :head_pipeline, Types::Ci::PipelineType, null: true, method: :actual_head_pipeline,
          description: 'The pipeline running on the branch HEAD of the merge request'
    field :pipelines,
          null: true,
          description: 'Pipelines for the merge request',
          resolver: Resolvers::MergeRequestPipelinesResolver

    field :milestone, Types::MilestoneType, null: true,
          description: 'The milestone of the merge request'
    field :assignees, Types::UserType.connection_type, null: true, complexity: 5,
          description: 'Assignees of the merge request'
    field :author, Types::UserType, null: true,
          description: 'User who created this merge request'
    field :participants, Types::UserType.connection_type, null: true, complexity: 5,
          description: 'Participants in the merge request'
    field :subscribed, GraphQL::BOOLEAN_TYPE, method: :subscribed?, null: false, complexity: 5,
          description: 'Indicates if the currently logged in user is subscribed to this merge request'
    field :labels, Types::LabelType.connection_type, null: true, complexity: 5,
          description: 'Labels of the merge request'
    field :discussion_locked, GraphQL::BOOLEAN_TYPE,
          description: 'Indicates if comments on the merge request are locked to members only',
          null: false
    field :time_estimate, GraphQL::INT_TYPE, null: false,
          description: 'Time estimate of the merge request'
    field :total_time_spent, GraphQL::INT_TYPE, null: false,
          description: 'Total time reported as spent on the merge request'
    field :reference, GraphQL::STRING_TYPE, null: false, method: :to_reference,
          description: 'Internal reference of the merge request. Returned in shortened format by default' do
      argument :full, GraphQL::BOOLEAN_TYPE, required: false, default_value: false,
               description: 'Boolean option specifying whether the reference should be returned in full'
    end
    field :task_completion_status, Types::TaskCompletionStatus, null: false,
          description: Types::TaskCompletionStatus.description
    field :commit_count, GraphQL::INT_TYPE, null: true,
          description: 'Number of commits in the merge request'
    field :conflicts, GraphQL::BOOLEAN_TYPE, null: false, method: :cannot_be_merged?,
          description: 'Indicates if the merge request has conflicts'
    field :auto_merge_enabled, GraphQL::BOOLEAN_TYPE, null: false,
          description: 'Indicates if auto merge is enabled for the merge request'

    field :approved_by, Types::UserType.connection_type, null: true,
          description: 'Users who approved the merge request'

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

    def commit_count
      object&.metrics&.commits_count
    end

    def source_branch_protected
      object.source_project.present? && ProtectedBranch.protected?(object.source_project, object.source_branch)
    end

    def discussion_locked
      !!object.discussion_locked
    end
  end
end

Types::MergeRequestType.prepend_if_ee('::EE::Types::MergeRequestType')
