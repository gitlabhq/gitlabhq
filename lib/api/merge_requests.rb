# frozen_string_literal: true

module API
  class MergeRequests < Grape::API
    include PaginationParams

    before { authenticate_non_get! }

    helpers ::Gitlab::IssuableMetadata

    # EE::API::MergeRequests would override the following helpers
    helpers do
      params :optional_params_ee do
      end

      params :optional_merge_requests_search_params do
      end
    end

    def self.update_params_at_least_one_of
      %i[
        assignee_id
        assignee_ids
        description
        labels
        milestone_id
        remove_source_branch
        state_event
        target_branch
        title
        discussion_locked
        squash
      ]
    end

    prepend_if_ee('EE::API::MergeRequests') # rubocop: disable Cop/InjectEnterpriseEditionModule

    helpers do
      # rubocop: disable CodeReuse/ActiveRecord
      def find_merge_requests(args = {})
        args = declared_params.merge(args)
        args[:milestone_title] = args.delete(:milestone)
        args[:label_name] = args.delete(:labels)
        args[:scope] = args[:scope].underscore if args[:scope]

        merge_requests = MergeRequestsFinder.new(current_user, args).execute
                           .reorder(order_options_with_tie_breaker)
        merge_requests = paginate(merge_requests)
                           .preload(:source_project, :target_project)

        return merge_requests if args[:view] == 'simple'

        merge_requests
          .with_api_entity_associations
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def merge_request_pipelines_with_access
        authorize! :read_pipeline, user_project

        mr = find_merge_request_with_access(params[:merge_request_iid])
        mr.all_pipelines
      end

      def check_sha_param!(params, merge_request)
        if params[:sha] && merge_request.diff_head_sha != params[:sha]
          render_api_error!("SHA does not match HEAD of source branch: #{merge_request.diff_head_sha}", 409)
        end
      end

      def automatically_mergeable?(merge_when_pipeline_succeeds, merge_request)
        pipeline_active = merge_request.head_pipeline_active? || merge_request.actual_head_pipeline_active?
        merge_when_pipeline_succeeds && merge_request.mergeable_state?(skip_ci_check: true) && pipeline_active
      end

      def immediately_mergeable?(merge_when_pipeline_succeeds, merge_request)
        if merge_when_pipeline_succeeds
          merge_request.actual_head_pipeline_success?
        else
          merge_request.mergeable_state?
        end
      end

      def serializer_options_for(merge_requests)
        options = { with: Entities::MergeRequestBasic, current_user: current_user, with_labels_details: declared_params[:with_labels_details] }

        if params[:view] == 'simple'
          options[:with] = Entities::MergeRequestSimple
        else
          options[:issuable_metadata] = issuable_meta_data(merge_requests, 'MergeRequest', current_user)
        end

        options
      end

      def authorize_push_to_merge_request!(merge_request)
        forbidden!('Source branch does not exist') unless
          merge_request.source_branch_exists?

        user_access = Gitlab::UserAccess.new(
          current_user,
          project: merge_request.source_project
        )

        forbidden!('Cannot push to source branch') unless
          user_access.can_push_to_branch?(merge_request.source_branch)
      end

      params :merge_requests_params do
        optional :state, type: String, values: %w[opened closed locked merged all], default: 'all',
                         desc: 'Return opened, closed, locked, merged, or all merge requests'
        optional :order_by, type: String, values: %w[created_at updated_at], default: 'created_at',
                            desc: 'Return merge requests ordered by `created_at` or `updated_at` fields.'
        optional :sort, type: String, values: %w[asc desc], default: 'desc',
                        desc: 'Return merge requests sorted in `asc` or `desc` order.'
        optional :milestone, type: String, desc: 'Return merge requests for a specific milestone'
        optional :labels, type: Array[String], coerce_with: Validations::Types::LabelsList.coerce, desc: 'Comma-separated list of label names'
        optional :with_labels_details, type: Boolean, desc: 'Return titles of labels and other details', default: false
        optional :created_after, type: DateTime, desc: 'Return merge requests created after the specified time'
        optional :created_before, type: DateTime, desc: 'Return merge requests created before the specified time'
        optional :updated_after, type: DateTime, desc: 'Return merge requests updated after the specified time'
        optional :updated_before, type: DateTime, desc: 'Return merge requests updated before the specified time'
        optional :view, type: String, values: %w[simple], desc: 'If simple, returns the `iid`, URL, title, description, and basic state of merge request'
        optional :author_id, type: Integer, desc: 'Return merge requests which are authored by the user with the given ID'
        optional :assignee_id, types: [Integer, String], integer_none_any: true,
                               desc: 'Return merge requests which are assigned to the user with the given ID'
        optional :scope, type: String, values: %w[created-by-me assigned-to-me created_by_me assigned_to_me all],
                         desc: 'Return merge requests for the given scope: `created_by_me`, `assigned_to_me` or `all`'
        optional :my_reaction_emoji, type: String, desc: 'Return issues reacted by the authenticated user by the given emoji'
        optional :source_branch, type: String, desc: 'Return merge requests with the given source branch'
        optional :source_project_id, type: Integer, desc: 'Return merge requests with the given source project id'
        optional :target_branch, type: String, desc: 'Return merge requests with the given target branch'
        optional :search, type: String, desc: 'Search merge requests for text present in the title, description, or any combination of these'
        optional :in, type: String, desc: '`title`, `description`, or a string joining them with comma'
        optional :wip, type: String, values: %w[yes no], desc: 'Search merge requests for WIP in the title'

        use :optional_merge_requests_search_params
        use :pagination
      end
    end

    resource :merge_requests do
      desc 'List merge requests' do
        success Entities::MergeRequestBasic
      end
      params do
        use :merge_requests_params
        optional :scope, type: String, values: %w[created-by-me assigned-to-me created_by_me assigned_to_me all], default: 'created_by_me',
                         desc: 'Return merge requests for the given scope: `created_by_me`, `assigned_to_me` or `all`'
      end
      get do
        authenticate! unless params[:scope] == 'all'
        merge_requests = find_merge_requests

        present merge_requests, serializer_options_for(merge_requests)
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end
    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get a list of group merge requests' do
        success Entities::MergeRequestBasic
      end
      params do
        use :merge_requests_params
      end
      get ":id/merge_requests" do
        merge_requests = find_merge_requests(group_id: user_group.id, include_subgroups: true)

        present merge_requests, serializer_options_for(merge_requests).merge(group: user_group)
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      include TimeTrackingEndpoints

      helpers do
        def handle_merge_request_errors!(errors)
          if errors[:project_access].any?
            error!(errors[:project_access], 422)
          elsif errors[:branch_conflict].any?
            error!(errors[:branch_conflict], 422)
          elsif errors[:validate_fork].any?
            error!(errors[:validate_fork], 422)
          elsif errors[:validate_branches].any?
            conflict!(errors[:validate_branches])
          elsif errors[:base].any?
            error!(errors[:base], 422)
          end

          render_api_error!(errors, 400)
        end

        params :optional_params do
          optional :description, type: String, desc: 'The description of the merge request'
          optional :assignee_id, type: Integer, desc: 'The ID of a user to assign the merge request'
          optional :assignee_ids, type: Array[Integer], desc: 'The array of user IDs to assign issue'
          optional :milestone_id, type: Integer, desc: 'The ID of a milestone to assign the merge request'
          optional :labels, type: Array[String], coerce_with: Validations::Types::LabelsList.coerce, desc: 'Comma-separated list of label names'
          optional :remove_source_branch, type: Boolean, desc: 'Remove source branch when merging'
          optional :allow_collaboration, type: Boolean, desc: 'Allow commits from members who can merge to the target branch'
          optional :allow_maintainer_to_push, type: Boolean, as: :allow_collaboration, desc: '[deprecated] See allow_collaboration'
          optional :squash, type: Grape::API::Boolean, desc: 'When true, the commits will be squashed into a single commit on merge'

          use :optional_params_ee
        end
      end

      desc 'List merge requests' do
        success Entities::MergeRequestBasic
      end
      params do
        use :merge_requests_params
        optional :iids, type: Array[Integer], desc: 'The IID array of merge requests'
      end
      get ":id/merge_requests" do
        authorize! :read_merge_request, user_project

        merge_requests = find_merge_requests(project_id: user_project.id)

        options = serializer_options_for(merge_requests).merge(project: user_project)
        options[:project] = user_project

        present merge_requests, options
      end

      desc 'Create a merge request' do
        success Entities::MergeRequest
      end
      params do
        requires :title, type: String, desc: 'The title of the merge request'
        requires :source_branch, type: String, desc: 'The source branch'
        requires :target_branch, type: String, desc: 'The target branch'
        optional :target_project_id, type: Integer,
                                     desc: 'The target project of the merge request defaults to the :id of the project'
        use :optional_params
      end
      post ":id/merge_requests" do
        Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-foss/issues/42316')

        authorize! :create_merge_request_from, user_project

        mr_params = declared_params(include_missing: false)
        mr_params[:force_remove_source_branch] = mr_params.delete(:remove_source_branch)
        mr_params = convert_parameters_from_legacy_format(mr_params)

        merge_request = ::MergeRequests::CreateService.new(user_project, current_user, mr_params).execute

        if merge_request.valid?
          present merge_request, with: Entities::MergeRequest, current_user: current_user, project: user_project
        else
          handle_merge_request_errors! merge_request.errors
        end
      end

      desc 'Delete a merge request'
      params do
        requires :merge_request_iid, type: Integer, desc: 'The IID of a merge request'
      end
      delete ":id/merge_requests/:merge_request_iid" do
        merge_request = find_project_merge_request(params[:merge_request_iid])

        authorize!(:destroy_merge_request, merge_request)

        destroy_conditionally!(merge_request) do |merge_request|
          Issuable::DestroyService.new(user_project, current_user).execute(merge_request)
        end
      end

      params do
        requires :merge_request_iid, type: Integer, desc: 'The IID of a merge request'
        optional :render_html, type: Boolean, desc: 'Returns the description and title rendered HTML'
        optional :include_diverged_commits_count, type: Boolean, desc: 'Returns the commits count behind the target branch'
        optional :include_rebase_in_progress, type: Boolean, desc: 'Returns whether a rebase operation is ongoing '
      end
      desc 'Get a single merge request' do
        success Entities::MergeRequest
      end
      get ':id/merge_requests/:merge_request_iid' do
        merge_request = find_merge_request_with_access(params[:merge_request_iid])

        present merge_request,
          with: Entities::MergeRequest,
          current_user: current_user,
          project: user_project,
          render_html: params[:render_html],
          include_diverged_commits_count: params[:include_diverged_commits_count],
          include_rebase_in_progress: params[:include_rebase_in_progress]
      end

      desc 'Get the participants of a merge request' do
        success Entities::UserBasic
      end
      get ':id/merge_requests/:merge_request_iid/participants' do
        merge_request = find_merge_request_with_access(params[:merge_request_iid])
        participants = ::Kaminari.paginate_array(merge_request.participants)

        present paginate(participants), with: Entities::UserBasic
      end

      desc 'Get the commits of a merge request' do
        success Entities::Commit
      end
      get ':id/merge_requests/:merge_request_iid/commits' do
        merge_request = find_merge_request_with_access(params[:merge_request_iid])

        commits =
          paginate(merge_request.merge_request_diff.merge_request_diff_commits)
            .map { |commit| Commit.from_hash(commit.to_hash, merge_request.project) }

        present commits, with: Entities::Commit
      end

      desc 'Show the merge request changes' do
        success Entities::MergeRequestChanges
      end
      get ':id/merge_requests/:merge_request_iid/changes' do
        merge_request = find_merge_request_with_access(params[:merge_request_iid])

        present merge_request, with: Entities::MergeRequestChanges, current_user: current_user, project: user_project
      end

      desc 'Get the merge request pipelines' do
        success Entities::PipelineBasic
      end
      get ':id/merge_requests/:merge_request_iid/pipelines' do
        pipelines = merge_request_pipelines_with_access

        present paginate(pipelines), with: Entities::PipelineBasic
      end

      desc 'Create a pipeline for merge request' do
        success Entities::Pipeline
      end
      post ':id/merge_requests/:merge_request_iid/pipelines' do
        authorize! :create_pipeline, user_project

        pipeline = ::MergeRequests::CreatePipelineService
          .new(user_project, current_user, allow_duplicate: true)
          .execute(find_merge_request_with_access(params[:merge_request_iid]))

        if pipeline.nil?
          not_allowed!
        elsif pipeline.persisted?
          status :ok
          present pipeline, with: Entities::Pipeline
        else
          render_validation_error!(pipeline)
        end
      end

      desc 'Update a merge request' do
        success Entities::MergeRequest
      end
      params do
        optional :title, type: String, allow_blank: false, desc: 'The title of the merge request'
        optional :target_branch, type: String, allow_blank: false, desc: 'The target branch'
        optional :state_event, type: String, values: %w[close reopen],
                               desc: 'Status of the merge request'
        optional :discussion_locked, type: Boolean, desc: 'Whether the MR discussion is locked'

        use :optional_params
        at_least_one_of(*::API::MergeRequests.update_params_at_least_one_of)
      end
      put ':id/merge_requests/:merge_request_iid' do
        Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-foss/issues/42318')

        merge_request = find_merge_request_with_access(params.delete(:merge_request_iid), :update_merge_request)

        mr_params = declared_params(include_missing: false)
        mr_params[:force_remove_source_branch] = mr_params.delete(:remove_source_branch) if mr_params.has_key?(:remove_source_branch)
        mr_params = convert_parameters_from_legacy_format(mr_params)

        merge_request = ::MergeRequests::UpdateService.new(user_project, current_user, mr_params).execute(merge_request)

        if merge_request.valid?
          present merge_request, with: Entities::MergeRequest, current_user: current_user, project: user_project
        else
          handle_merge_request_errors! merge_request.errors
        end
      end

      desc 'Merge a merge request' do
        success Entities::MergeRequest
      end
      params do
        optional :merge_commit_message, type: String, desc: 'Custom merge commit message'
        optional :squash_commit_message, type: String, desc: 'Custom squash commit message'
        optional :should_remove_source_branch, type: Boolean,
                                               desc: 'When true, the source branch will be deleted if possible'
        optional :merge_when_pipeline_succeeds, type: Boolean,
                                                desc: 'When true, this merge request will be merged when the pipeline succeeds'
        optional :sha, type: String, desc: 'When present, must have the HEAD SHA of the source branch'
        optional :squash, type: Grape::API::Boolean, desc: 'When true, the commits will be squashed into a single commit on merge'
      end
      put ':id/merge_requests/:merge_request_iid/merge' do
        Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-foss/issues/42317')

        merge_request = find_project_merge_request(params[:merge_request_iid])

        # Merge request can not be merged
        # because user dont have permissions to push into target branch
        unauthorized! unless merge_request.can_be_merged_by?(current_user)

        merge_when_pipeline_succeeds = to_boolean(params[:merge_when_pipeline_succeeds])
        automatically_mergeable = automatically_mergeable?(merge_when_pipeline_succeeds, merge_request)
        immediately_mergeable = immediately_mergeable?(merge_when_pipeline_succeeds, merge_request)

        not_allowed! if !immediately_mergeable && !automatically_mergeable

        render_api_error!('Branch cannot be merged', 406) unless merge_request.mergeable?(skip_ci_check: automatically_mergeable)

        check_sha_param!(params, merge_request)

        merge_request.update(squash: params[:squash]) if params[:squash]

        merge_params = HashWithIndifferentAccess.new(
          commit_message: params[:merge_commit_message],
          squash_commit_message: params[:squash_commit_message],
          should_remove_source_branch: params[:should_remove_source_branch],
          sha: params[:sha] || merge_request.diff_head_sha
        )

        if immediately_mergeable
          ::MergeRequests::MergeService
            .new(merge_request.target_project, current_user, merge_params)
            .execute(merge_request)
        elsif automatically_mergeable
          AutoMergeService.new(merge_request.target_project, current_user, merge_params)
            .execute(merge_request, AutoMergeService::STRATEGY_MERGE_WHEN_PIPELINE_SUCCEEDS)
        end

        present merge_request, with: Entities::MergeRequest, current_user: current_user, project: user_project
      end

      desc 'Returns the up to date merge-ref HEAD commit'
      get ':id/merge_requests/:merge_request_iid/merge_ref' do
        merge_request = find_project_merge_request(params[:merge_request_iid])

        result = ::MergeRequests::MergeabilityCheckService.new(merge_request).execute(recheck: true)

        if result.success?
          present :commit_id, result.payload.dig(:merge_ref_head, :commit_id)
        else
          render_api_error!(result.message, 400)
        end
      end

      desc 'Cancel merge if "Merge When Pipeline Succeeds" is enabled' do
        success Entities::MergeRequest
      end
      post ':id/merge_requests/:merge_request_iid/cancel_merge_when_pipeline_succeeds' do
        merge_request = find_project_merge_request(params[:merge_request_iid])

        unauthorized! unless merge_request.can_cancel_auto_merge?(current_user)

        AutoMergeService.new(merge_request.target_project, current_user).cancel(merge_request)
      end

      desc 'Rebase the merge request against its target branch' do
        detail 'This feature was added in GitLab 11.6'
      end
      put ':id/merge_requests/:merge_request_iid/rebase' do
        merge_request = find_project_merge_request(params[:merge_request_iid])

        authorize_push_to_merge_request!(merge_request)

        merge_request.rebase_async(current_user.id)

        status :accepted
        present rebase_in_progress: merge_request.rebase_in_progress?
      rescue ::MergeRequest::RebaseLockTimeout => e
        render_api_error!(e.message, 409)
      end

      desc 'List issues that will be closed on merge' do
        success Entities::MRNote
      end
      params do
        use :pagination
      end
      get ':id/merge_requests/:merge_request_iid/closes_issues' do
        merge_request = find_merge_request_with_access(params[:merge_request_iid])
        issues = ::Kaminari.paginate_array(merge_request.visible_closing_issues_for(current_user))
        issues = paginate(issues)

        external_issues, internal_issues = issues.partition { |issue| issue.is_a?(ExternalIssue) }

        data = Entities::IssueBasic.represent(internal_issues, current_user: current_user)
        data += Entities::ExternalIssue.represent(external_issues, current_user: current_user)

        data.as_json
      end
    end
  end
end
