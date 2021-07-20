# frozen_string_literal: true

module API
  class MergeRequests < ::API::Base
    include PaginationParams

    CONTEXT_COMMITS_POST_LIMIT = 20

    before { authenticate_non_get! }

    helpers Helpers::MergeRequestsHelpers
    helpers Helpers::SSEHelpers

    # These endpoints are defined in `TimeTrackingEndpoints` and is shared by
    # API::Issues. In order to be able to define the feature category of these
    # endpoints, we need to define them at the top-level by route.
    feature_category :code_review, [
      '/projects/:id/merge_requests/:merge_request_iid/time_estimate',
      '/projects/:id/merge_requests/:merge_request_iid/reset_time_estimate',
      '/projects/:id/merge_requests/:merge_request_iid/add_spent_time',
      '/projects/:id/merge_requests/:merge_request_iid/reset_spent_time',
      '/projects/:id/merge_requests/:merge_request_iid/time_stats'
    ]

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
        reviewer_ids
        description
        labels
        add_labels
        remove_labels
        milestone_id
        remove_source_branch
        allow_collaboration
        allow_maintainer_to_push
        squash
        target_branch
        title
        state_event
        discussion_locked
      ]
    end

    prepend_mod_with('API::MergeRequests') # rubocop: disable Cop/InjectEnterpriseEditionModule

    helpers do
      # rubocop: disable CodeReuse/ActiveRecord
      def find_merge_requests(args = {})
        args = declared_params.merge(args)
        args[:milestone_title] = args.delete(:milestone)
        args[:not][:milestone_title] = args[:not]&.delete(:milestone)
        args[:label_name] = args.delete(:labels)
        args[:not][:label_name] = args[:not]&.delete(:labels)
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
        mr = find_merge_request_with_access(params[:merge_request_iid])
        ::Ci::PipelinesForMergeRequestFinder.new(mr, current_user).execute
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
          options[:skip_merge_status_recheck] = !declared_params[:with_merge_status_recheck]
        end

        options
      end

      def authorize_push_to_merge_request!(merge_request)
        forbidden!('Source branch does not exist') unless
          merge_request.source_branch_exists?

        user_access = Gitlab::UserAccess.new(
          current_user,
          container: merge_request.source_project
        )

        forbidden!('Cannot push to source branch') unless
          user_access.can_push_to_branch?(merge_request.source_branch)
      end

      params :merge_requests_params do
        use :merge_requests_base_params
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
        use :optional_scope_param
      end
      get feature_category: :code_review do
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
        optional :non_archived, type: Boolean, desc: 'Return merge requests from non archived projects',
        default: true
      end
      get ":id/merge_requests", feature_category: :code_review do
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
        params :optional_params do
          optional :assignee_id, type: Integer, desc: 'The ID of a user to assign the merge request'
          optional :assignee_ids, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce, desc: 'Comma-separated list of assignee ids'
          optional :reviewer_ids, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce, desc: 'Comma-separated list of reviewer ids'
          optional :description, type: String, desc: 'The description of the merge request'
          optional :labels, type: Array[String], coerce_with: Validations::Types::CommaSeparatedToArray.coerce, desc: 'Comma-separated list of label names'
          optional :add_labels, type: Array[String], coerce_with: Validations::Types::CommaSeparatedToArray.coerce, desc: 'Comma-separated list of label names'
          optional :remove_labels, type: Array[String], coerce_with: Validations::Types::CommaSeparatedToArray.coerce, desc: 'Comma-separated list of label names'
          optional :milestone_id, type: Integer, desc: 'The ID of a milestone to assign the merge request'
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
        optional :iids, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce, desc: 'The IID array of merge requests'
      end
      get ":id/merge_requests", feature_category: :code_review do
        authorize! :read_merge_request, user_project

        merge_requests = find_merge_requests(project_id: user_project.id)

        options = serializer_options_for(merge_requests).merge(project: user_project)
        options[:project] = user_project

        if Feature.enabled?(:api_caching_merge_requests, user_project, type: :development, default_enabled: :yaml)
          present_cached merge_requests, expires_in: 10.minutes, **options
        else
          present merge_requests, options
        end
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
      post ":id/merge_requests", feature_category: :code_review do
        Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/20770')

        authorize! :create_merge_request_from, user_project

        mr_params = declared_params(include_missing: false)
        mr_params[:force_remove_source_branch] = mr_params.delete(:remove_source_branch)
        mr_params = convert_parameters_from_legacy_format(mr_params)

        merge_request = ::MergeRequests::CreateService.new(project: user_project, current_user: current_user, params: mr_params).execute

        handle_merge_request_errors!(merge_request)

        Gitlab::UsageDataCounters::EditorUniqueCounter.track_sse_edit_action(author: current_user) if request_from_sse?(user_project)

        present merge_request, with: Entities::MergeRequest, current_user: current_user, project: user_project
      end

      desc 'Delete a merge request'
      params do
        requires :merge_request_iid, type: Integer, desc: 'The IID of a merge request'
      end
      delete ":id/merge_requests/:merge_request_iid", feature_category: :code_review do
        merge_request = find_project_merge_request(params[:merge_request_iid])

        authorize!(:destroy_merge_request, merge_request)

        destroy_conditionally!(merge_request) do |merge_request|
          Issuable::DestroyService.new(project: user_project, current_user: current_user).execute(merge_request)
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
      get ':id/merge_requests/:merge_request_iid', feature_category: :code_review do
        not_found!("Merge Request") unless can?(current_user, :read_merge_request, user_project)

        merge_request = find_merge_request_with_access(params[:merge_request_iid])

        present merge_request,
          with: Entities::MergeRequest,
          current_user: current_user,
          project: user_project,
          render_html: params[:render_html],
          include_first_contribution: true,
          include_diverged_commits_count: params[:include_diverged_commits_count],
          include_rebase_in_progress: params[:include_rebase_in_progress]
      end

      desc 'Get the participants of a merge request' do
        success Entities::UserBasic
      end
      get ':id/merge_requests/:merge_request_iid/participants', feature_category: :code_review do
        not_found!("Merge Request") unless can?(current_user, :read_merge_request, user_project)

        merge_request = find_merge_request_with_access(params[:merge_request_iid])

        participants = ::Kaminari.paginate_array(merge_request.participants)

        present paginate(participants), with: Entities::UserBasic
      end

      desc 'Get the commits of a merge request' do
        success Entities::Commit
      end
      get ':id/merge_requests/:merge_request_iid/commits', feature_category: :code_review do
        not_found!("Merge Request") unless can?(current_user, :read_merge_request, user_project)

        merge_request = find_merge_request_with_access(params[:merge_request_iid])

        commits =
          paginate(merge_request.merge_request_diff.merge_request_diff_commits)
            .map { |commit| Commit.from_hash(commit.to_hash, merge_request.project) }

        present commits, with: Entities::Commit
      end

      desc 'Get the context commits of a merge request' do
        success Entities::Commit
      end
      get ':id/merge_requests/:merge_request_iid/context_commits', feature_category: :code_review do
        merge_request = find_merge_request_with_access(params[:merge_request_iid])
        project = merge_request.project

        not_found! unless project.context_commits_enabled?

        context_commits =
          paginate(merge_request.merge_request_context_commits).map(&:to_commit)

        present context_commits, with: Entities::CommitWithLink, type: :full, request: merge_request
      end

      params do
        requires :commits, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce, allow_blank: false, desc: 'List of context commits sha'
      end
      desc 'create context commits of merge request' do
        success Entities::Commit
      end
      post ':id/merge_requests/:merge_request_iid/context_commits', feature_category: :code_review do
        commit_ids = params[:commits]

        if commit_ids.size > CONTEXT_COMMITS_POST_LIMIT
          render_api_error!("Context commits array size should not be more than #{CONTEXT_COMMITS_POST_LIMIT}", 400)
        end

        merge_request = find_merge_request_with_access(params[:merge_request_iid])
        project = merge_request.project

        not_found! unless project.context_commits_enabled?

        authorize!(:update_merge_request, merge_request)

        project = merge_request.target_project
        result = ::MergeRequests::AddContextService.new(project: project, current_user: current_user, params: { merge_request: merge_request, commits: commit_ids }).execute

        if result.instance_of?(Array)
          present result, with: Entities::Commit
        else
          render_api_error!(result[:message], result[:http_status])
        end
      end

      params do
        requires :commits, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce, allow_blank: false, desc: 'List of context commits sha'
      end
      desc 'remove context commits of merge request'
      delete ':id/merge_requests/:merge_request_iid/context_commits', feature_category: :code_review do
        commit_ids = params[:commits]
        merge_request = find_merge_request_with_access(params[:merge_request_iid])
        project = merge_request.project

        not_found! unless project.context_commits_enabled?

        authorize!(:destroy_merge_request, merge_request)
        project = merge_request.target_project
        commits = project.repository.commits_by(oids: commit_ids)

        if commits.size != commit_ids.size
          render_api_error!("One or more context commits' sha is not valid.", 400)
        end

        MergeRequestContextCommit.delete_bulk(merge_request, commits)
        status 204
      end

      desc 'Show the merge request changes' do
        success Entities::MergeRequestChanges
      end
      get ':id/merge_requests/:merge_request_iid/changes', feature_category: :code_review do
        not_found!("Merge Request") unless can?(current_user, :read_merge_request, user_project)

        merge_request = find_merge_request_with_access(params[:merge_request_iid])

        present merge_request,
          with: Entities::MergeRequestChanges,
          current_user: current_user,
          project: user_project,
          access_raw_diffs: to_boolean(params.fetch(:access_raw_diffs, false))
      end

      desc 'Get the merge request pipelines' do
        success Entities::Ci::PipelineBasic
      end
      get ':id/merge_requests/:merge_request_iid/pipelines', feature_category: :continuous_integration do
        pipelines = merge_request_pipelines_with_access

        not_found!("Merge Request") unless can?(current_user, :read_merge_request, user_project)

        present paginate(pipelines), with: Entities::Ci::PipelineBasic
      end

      desc 'Create a pipeline for merge request' do
        success ::API::Entities::Ci::Pipeline
      end
      post ':id/merge_requests/:merge_request_iid/pipelines', feature_category: :continuous_integration do
        pipeline = ::MergeRequests::CreatePipelineService
          .new(project: user_project, current_user: current_user, params: { allow_duplicate: true })
          .execute(find_merge_request_with_access(params[:merge_request_iid]))
          .payload

        if pipeline.nil?
          not_allowed!
        elsif pipeline.persisted?
          status :ok
          present pipeline, with: ::API::Entities::Ci::Pipeline
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
      put ':id/merge_requests/:merge_request_iid', feature_category: :code_review do
        Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/20772')

        merge_request = find_merge_request_with_access(params.delete(:merge_request_iid), :update_merge_request)

        mr_params = declared_params(include_missing: false)
        mr_params[:force_remove_source_branch] = mr_params.delete(:remove_source_branch) if mr_params.has_key?(:remove_source_branch)
        mr_params = convert_parameters_from_legacy_format(mr_params)
        mr_params[:use_specialized_service] = true

        merge_request = ::MergeRequests::UpdateService
          .new(project: user_project, current_user: current_user, params: mr_params)
          .execute(merge_request)

        handle_merge_request_errors!(merge_request)

        present merge_request, with: Entities::MergeRequest, current_user: current_user, project: user_project
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
      put ':id/merge_requests/:merge_request_iid/merge', feature_category: :code_review do
        Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/4796')

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
        ).compact

        if immediately_mergeable
          ::MergeRequests::MergeService
            .new(project: merge_request.target_project, current_user: current_user, params: merge_params)
            .execute(merge_request)
        elsif automatically_mergeable
          AutoMergeService.new(merge_request.target_project, current_user, merge_params)
            .execute(merge_request, AutoMergeService::STRATEGY_MERGE_WHEN_PIPELINE_SUCCEEDS)
        end

        present merge_request, with: Entities::MergeRequest, current_user: current_user, project: user_project
      end

      desc 'Returns the up to date merge-ref HEAD commit'
      get ':id/merge_requests/:merge_request_iid/merge_ref', feature_category: :code_review do
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
      post ':id/merge_requests/:merge_request_iid/cancel_merge_when_pipeline_succeeds', feature_category: :code_review do
        merge_request = find_project_merge_request(params[:merge_request_iid])

        unauthorized! unless merge_request.can_cancel_auto_merge?(current_user)

        AutoMergeService.new(merge_request.target_project, current_user).cancel(merge_request)
      end

      desc 'Rebase the merge request against its target branch' do
        detail 'This feature was added in GitLab 11.6'
      end
      params do
        optional :skip_ci, type: Boolean, desc: 'Do not create CI pipeline'
      end
      put ':id/merge_requests/:merge_request_iid/rebase', feature_category: :code_review do
        merge_request = find_project_merge_request(params[:merge_request_iid])

        authorize_push_to_merge_request!(merge_request)

        merge_request.rebase_async(current_user.id, skip_ci: params[:skip_ci])

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
      get ':id/merge_requests/:merge_request_iid/closes_issues', feature_category: :code_review do
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
