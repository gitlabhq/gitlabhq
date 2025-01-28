# frozen_string_literal: true

module API
  class MergeRequests < ::API::Base
    include APIGuard
    include PaginationParams
    include Helpers::Unidiff

    helpers ::API::Helpers::HeadersHelpers

    CONTEXT_COMMITS_POST_LIMIT = 20

    before { authenticate_non_get! }

    allow_access_with_scope :ai_workflows, if: ->(request) do
      request.get? || request.head? ||
        (request.put? && request.path.match?(%r{/api/v\d+/projects/\d+/merge_requests/\d+$})) # Only allow basic MR updates
    end

    rescue_from ActiveRecord::QueryCanceled do |_e|
      render_api_error!({ error: 'Request timed out' }, 408)
    end

    helpers Helpers::MergeRequestsHelpers

    # These endpoints are defined in `TimeTrackingEndpoints` and is shared by
    # API::Issues. In order to be able to define the feature category of these
    # endpoints, we need to define them at the top-level by route.
    feature_category :code_review_workflow, [
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

      params :optional_merge_params_ee do
      end

      params :optional_merge_requests_search_params do
      end

      def ci_params
        {}
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
        merge_after
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
        merge_requests = order_merge_requests(merge_requests)
        merge_requests = paginate(merge_requests)
                           .preload(:source_project, :target_project)

        return merge_requests if args[:view] == 'simple'

        merge_requests
          .with_api_entity_associations
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def render_merge_requests(merge_requests, options, skip_cache: false)
        return present merge_requests, options if skip_cache

        cache_context = ->(mr) do
          [
            current_user&.cache_key,
            mr.merge_status,
            mr.labels.map(&:cache_key),
            mr.merge_request_assignees.map(&:cache_key),
            mr.merge_request_reviewers.map(&:cache_key)
          ].join(":")
        end

        present_cached merge_requests,
          expires_in: 8.hours,
          cache_context: cache_context,
          **options
      end

      def merge_request_pipelines_with_access
        mr = find_merge_request_with_access(params[:merge_request_iid])
        ::Ci::PipelinesForMergeRequestFinder.new(mr, current_user).execute
      end

      def automatically_mergeable?(merge_when_pipeline_succeeds, merge_request)
        available_strategies = AutoMergeService.new(merge_request.project,
          current_user).available_strategies(merge_request)

        merge_when_pipeline_succeeds && available_strategies.include?(merge_request.default_auto_merge_strategy)
      end

      def immediately_mergeable?(merge_when_pipeline_succeeds, merge_request)
        if merge_when_pipeline_succeeds
          merge_request.diff_head_pipeline_success?
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

      def authorize_merge_request_rebase!(merge_request)
        result = ::MergeRequests::RebaseService
          .new(project: merge_request.source_project, current_user: current_user)
          .validate(merge_request)

        forbidden!(result.message) if result.error?
      end

      def recheck_mergeability_of(merge_requests:)
        return unless can?(current_user, :update_merge_request, user_project)

        merge_requests.each { |mr| mr.check_mergeability(async: true) }
      end

      def batch_process_mergeability_checks(merge_requests)
        ::MergeRequests::MergeabilityCheckBatchService.new(merge_requests, current_user).execute
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def order_merge_requests(merge_requests)
        if params[:order_by] == 'merged_at'
          case params[:sort]
          when 'desc'
            return merge_requests.reorder_by_metric('merged_at', 'DESC')
          else
            return merge_requests.reorder_by_metric('merged_at', 'ASC')
          end
        end

        merge_requests.reorder(order_options_with_tie_breaker(override_created_at: false))
      end
      # rubocop: enable CodeReuse/ActiveRecord

      params :merge_requests_params do
        use :merge_requests_base_params
        use :optional_merge_requests_search_params
        use :pagination
      end
    end

    resource :merge_requests do
      desc 'List merge requests' do
        detail 'Get all merge requests the authenticated user has access to. By default it returns only merge requests created by the current user. To get all merge requests, use parameter `scope=all`.'
        success Entities::MergeRequestBasic
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 422, message: 'Unprocessable entity' }
        ]
        tags %w[merge_requests]
      end
      params do
        use :merge_requests_params
        use :optional_scope_param
      end
      get feature_category: :code_review_workflow, urgency: :low do
        authenticate! unless params[:scope] == 'all'
        validate_search_rate_limit! if declared_params[:search].present?
        merge_requests = find_merge_requests

        present merge_requests, serializer_options_for(merge_requests)
      end
    end

    params do
      requires :id, type: String, desc: 'The ID or URL-encoded path of the group owned by the authenticated user.'
    end
    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'List group merge requests' do
        detail 'Get all merge requests for this group and its subgroups.'
        success Entities::MergeRequestBasic
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' },
          { code: 422, message: 'Unprocessable entity' }
        ]
        tags %w[merge_requests]
      end
      params do
        use :merge_requests_params
        optional :non_archived, type: Boolean,
          default: true,
          desc: 'Returns merge requests from non archived projects only.'
      end
      get ":id/merge_requests", feature_category: :code_review_workflow, urgency: :low do
        validate_search_rate_limit! if declared_params[:search].present?
        merge_requests = find_merge_requests(group_id: user_group.id, include_subgroups: true)
        options = serializer_options_for(merge_requests).merge(group: user_group)

        unless options[:skip_merge_status_recheck]
          batch_process_mergeability_checks(merge_requests)

          # NOTE: skipping individual mergeability checks in the presenter
          options[:skip_merge_status_recheck] = true
        end

        present merge_requests, options
      end
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project.'
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      include TimeTrackingEndpoints

      helpers do
        params :optional_params do
          optional :assignee_id, type: Integer, desc: 'Assignee user ID.'
          optional :assignee_ids, type: Array[Integer],
            coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce,
            desc: 'The IDs of the users to assign the merge request to, as a comma-separated list. Set to 0 or provide an empty value to unassign all assignees.',
            documentation: { is_array: true }
          optional :reviewer_ids, type: Array[Integer],
            coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce,
            desc: 'The IDs of the users to review the merge request, as a comma-separated list. Set to 0 or provide an empty value to unassign all reviewers.',
            documentation: { is_array: true }
          optional :description, type: String, desc: 'Description of the merge request. Limited to 1,048,576 characters.'
          optional :labels, type: Array[String],
            coerce_with: Validations::Types::CommaSeparatedToArray.coerce,
            desc: 'Comma-separated label names for a merge request. Set to an empty string to unassign all labels.',
            documentation: { is_array: true }
          optional :add_labels, type: Array[String],
            coerce_with: Validations::Types::CommaSeparatedToArray.coerce,
            desc: 'Comma-separated label names to add to a merge request.',
            documentation: { is_array: true }
          optional :remove_labels, type: Array[String],
            coerce_with: Validations::Types::CommaSeparatedToArray.coerce,
            desc: 'Comma-separated label names to remove from a merge request.',
            documentation: { is_array: true }
          optional :milestone_id, type: Integer, desc: 'The global ID of a milestone to assign the merge reques to.'
          optional :remove_source_branch, type: Boolean, desc: 'Flag indicating if a merge request should remove the source branch when merging.'
          optional :allow_collaboration, type: Boolean, desc: 'Allow commits from members who can merge to the target branch.'
          optional :allow_maintainer_to_push, type: Boolean, as: :allow_collaboration, desc: '[deprecated] See allow_collaboration'
          optional :squash, type: Grape::API::Boolean, desc: 'Squash commits into a single commit when merging.'
          optional :merge_after, type: String, desc: 'Date after which the merge request can be merged.'

          use :optional_params_ee
        end

        params :optional_merge_params do
          use :optional_merge_params_ee
        end
      end

      desc 'List project merge requests' do
        detail 'Get all merge requests for this project.'
        success Entities::MergeRequestBasic
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' },
          { code: 422, message: 'Unprocessable entity' }
        ]
        tags %w[merge_requests]
      end
      params do
        use :merge_requests_params

        optional :iids, type: Array[Integer],
          coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce,
          desc: 'Returns the request having the given `iid`.',
          documentation: { is_array: true }
      end
      get ":id/merge_requests", feature_category: :code_review_workflow, urgency: :low do
        authorize! :read_merge_request, user_project
        validate_search_rate_limit! if declared_params[:search].present?

        merge_requests = find_merge_requests(project_id: user_project.id)

        options = serializer_options_for(merge_requests).merge(project: user_project)
        options[:project] = user_project

        recheck_mergeability_of(merge_requests: merge_requests) unless options[:skip_merge_status_recheck]

        skip_cache = [
          declared_params[:with_labels_details] == true
        ].any?

        render_merge_requests(merge_requests, options, skip_cache: skip_cache)
      end

      desc 'Create merge request' do
        detail 'Create a new merge request.'
        failure [
          { code: 400, message: 'Bad request' },
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' },
          { code: 409, message: 'Conflict' },
          { code: 422, message: 'Unprocessable entity' }
        ]
        success Entities::MergeRequest
        tags %w[merge_requests]
      end
      params do
        requires :title, type: String, desc: 'The title of the merge request.'
        requires :source_branch, type: String, desc: 'The source branch.'
        requires :target_branch, type: String, desc: 'The target branch.'
        optional :target_project_id, type: Integer,
          desc: 'The target project of the merge request defaults to the :id of the project.'
        use :optional_params
      end
      post ":id/merge_requests", feature_category: :code_review_workflow, urgency: :low do
        Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/20770')

        authorize! :create_merge_request_from, user_project

        mr_params = declared_params(include_missing: false)
        mr_params[:force_remove_source_branch] = mr_params.delete(:remove_source_branch)
        mr_params = convert_parameters_from_legacy_format(mr_params)

        merge_request = ::MergeRequests::CreateService.new(project: user_project, current_user: current_user, params: mr_params).execute

        handle_merge_request_errors!(merge_request)

        present merge_request, with: Entities::MergeRequest, current_user: current_user, project: user_project
      end

      desc 'Delete a merge request' do
        detail 'Only for administrators and project owners. Deletes the merge request in question. '
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' },
          { code: 412, message: 'Precondition failed' }
        ]
        tags %w[merge_requests]
      end
      params do
        requires :merge_request_iid, type: Integer, desc: 'The internal ID of the merge request.'
      end
      delete ":id/merge_requests/:merge_request_iid", feature_category: :code_review_workflow, urgency: :low do
        merge_request = find_project_merge_request(params[:merge_request_iid])

        authorize!(:destroy_merge_request, merge_request)

        destroy_conditionally!(merge_request) do |merge_request|
          Issuable::DestroyService.new(container: user_project, current_user: current_user).execute(merge_request)
        end
      end

      params do
        requires :merge_request_iid, type: Integer, desc: 'The internal ID of the merge request.'
        optional :render_html, type: Boolean, desc: 'If `true`, response includes rendered HTML for title and description.'
        optional :include_diverged_commits_count, type: Boolean, desc: 'If `true`, response includes the commits behind the target branch.'
        optional :include_rebase_in_progress, type: Boolean, desc: 'If `true`, response includes whether a rebase operation is in progress.'
      end
      desc 'Get single merge request' do
        detail 'Shows information about a single merge request. Note: the `changes_count` value in the response is a string, not an integer. This is because when an merge request has too many changes to display and store, it is capped at 1,000. In that case, the API returns the string `"1000+"` for the changes count.'

        success Entities::MergeRequest
        failure [
          { code: 404, message: 'Not found' }
        ]
        tags %w[merge_requests]
      end
      get ':id/merge_requests/:merge_request_iid', feature_category: :code_review_workflow, urgency: :low do
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

      desc 'Get single merge request participants' do
        detail 'Get a list of merge request participants.'
        success Entities::UserBasic
        failure [
          { code: 404, message: 'Not found' }
        ]
        tags %w[merge_requests]
      end
      get ':id/merge_requests/:merge_request_iid/participants', feature_category: :code_review_workflow, urgency: :low do
        merge_request = find_merge_request_with_access(params[:merge_request_iid])

        participants = ::Kaminari.paginate_array(merge_request.visible_participants(current_user))

        present paginate(participants), with: Entities::UserBasic
      end

      desc 'Get single merge request reviewers' do
        detail 'Get a list of merge request reviewers.'
        success Entities::MergeRequestReviewer
        failure [
          { code: 404, message: 'Not found' }
        ]
        tags %w[merge_requests]
      end
      get ':id/merge_requests/:merge_request_iid/reviewers', feature_category: :code_review_workflow, urgency: :low do
        merge_request = find_merge_request_with_access(params[:merge_request_iid])

        reviewers = ::Kaminari.paginate_array(merge_request.merge_request_reviewers)

        present paginate(reviewers), with: Entities::MergeRequestReviewer
      end

      desc 'Get single merge request commits' do
        detail 'Get a list of merge request commits.'
        success Entities::Commit
        failure [
          { code: 404, message: 'Not found' }
        ]
        tags %w[merge_requests]
      end
      get ':id/merge_requests/:merge_request_iid/commits', feature_category: :code_review_workflow, urgency: :low do
        merge_request = find_merge_request_with_access(params[:merge_request_iid])

        commits =
          paginate(merge_request.merge_request_diff.merge_request_diff_commits)
            .map { |commit| Commit.from_hash(commit.to_hash, merge_request.project) }

        present commits, with: Entities::Commit
      end

      desc 'List merge request context commits' do
        detail 'Get a list of merge request context commits.'
        success Entities::Commit
        failure [
          { code: 404, message: 'Not found' }
        ]
        tags %w[merge_requests]
      end
      get ':id/merge_requests/:merge_request_iid/context_commits', feature_category: :code_review_workflow, urgency: :high do
        merge_request = find_merge_request_with_access(params[:merge_request_iid])
        context_commits =
          paginate(merge_request.merge_request_context_commits).map(&:to_commit)

        present context_commits, with: Entities::CommitWithLink, type: :full, request: merge_request
      end

      params do
        requires :commits, type: Array[String],
          coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce,
          allow_blank: false,
          desc: 'The context commits’ SHA.',
          documentation: { is_array: true }
      end
      desc 'Create merge request context commits' do
        detail 'Create a list of merge request context commits.'
        success Entities::Commit
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[merge_requests]
      end
      post ':id/merge_requests/:merge_request_iid/context_commits', feature_category: :code_review_workflow do
        commit_ids = params[:commits]

        if commit_ids.size > CONTEXT_COMMITS_POST_LIMIT
          render_api_error!("Context commits array size should not be more than #{CONTEXT_COMMITS_POST_LIMIT}", 400)
        end

        merge_request = find_merge_request_with_access(params[:merge_request_iid])

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
        requires :commits, type: Array[String],
          coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce,
          allow_blank: false,
          desc: 'The context commits’ SHA.',
          documentation: { is_array: true }
      end
      desc 'Delete merge request context commits' do
        detail 'Delete a list of merge request context commits.'
        failure [
          { code: 400, message: 'Bad request' },
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[merge_requests]
      end
      delete ':id/merge_requests/:merge_request_iid/context_commits', feature_category: :code_review_workflow do
        commit_ids = params[:commits]
        merge_request = find_merge_request_with_access(params[:merge_request_iid])

        authorize!(:destroy_merge_request, merge_request)
        project = merge_request.target_project
        commits = project.repository.commits_by(oids: commit_ids)

        if commits.size != commit_ids.size
          render_api_error!("One or more context commits' sha is not valid.", 400)
        end

        MergeRequestContextCommit.delete_bulk(merge_request, commits)
        status 204
      end

      desc 'Get single merge request changes' do
        detail 'Shows information about the merge request including its files and changes.'
        success Entities::MergeRequestChanges
        failure [
          { code: 404, message: 'Not found' }
        ]
        tags %w[merge_requests]
      end
      params do
        use :with_unidiff
      end
      get ':id/merge_requests/:merge_request_iid/changes', feature_category: :code_review_workflow, urgency: :low do
        merge_request = find_merge_request_with_access(params[:merge_request_iid])

        present merge_request,
          with: Entities::MergeRequestChanges,
          current_user: current_user,
          project: user_project,
          access_raw_diffs: to_boolean(params.fetch(:access_raw_diffs, false)),
          enable_unidiff: declared_params[:unidiff]
      end

      desc 'Get the merge request diffs' do
        detail 'Get a list of merge request diffs.'
        success Entities::Diff
        failure [
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[merge_requests]
      end
      params do
        use :pagination
        use :with_unidiff
      end
      get ':id/merge_requests/:merge_request_iid/diffs', feature_category: :code_review_workflow, urgency: :low do
        merge_request = find_merge_request_with_access(params[:merge_request_iid])

        present paginate(merge_request.merge_request_diff.paginated_diffs(params[:page], params[:per_page])).diffs, with: Entities::Diff, enable_unidiff: declared_params[:unidiff]
      end

      desc 'Get the merge request raw diffs' do
        detail 'Get the raw diffs of a merge request that can used programmatically.'
        failure [
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[merge_requests]
      end
      get ':id/merge_requests/:merge_request_iid/raw_diffs', feature_category: :code_review_workflow, urgency: :low do
        merge_request = find_merge_request_with_access(params[:merge_request_iid])

        no_cache_headers

        send_git_diff(merge_request.project.repository, merge_request.diff_refs)
      end

      desc 'Get single merge request pipelines' do
        detail 'Get a list of merge request pipelines.'
        success Entities::Ci::PipelineBasic
        failure [
          { code: 404, message: 'Not found' }
        ]
        tags %w[merge_requests]
      end
      get ':id/merge_requests/:merge_request_iid/pipelines', urgency: :low, feature_category: :pipeline_composition do
        pipelines = merge_request_pipelines_with_access
        present paginate(pipelines), with: Entities::Ci::PipelineBasic
      end

      desc 'Create merge request pipeline' do
        detail 'Create a new pipeline for a merge request. A pipeline created via this endpoint doesn’t run a regular branch/tag pipeline. It requires `.gitlab-ci.yml` to be configured with `only: [merge_requests]` to create jobs.'
        success ::API::Entities::Ci::Pipeline
        failure [
          { code: 400, message: 'Bad request' },
          { code: 404, message: 'Not found' },
          { code: 405, message: 'Method not allowed' }
        ]
        tags %w[merge_requests]
      end
      params do
        optional :async, type: Boolean, default: false,
          desc: 'Indicates if the merge request pipeline creation should be performed asynchronously. If set to `true`, the pipeline will be created outside of the API request and the endpoint will return an empty response with a `202` status code. When the response is `202`, the creation can still fail outside of this request.'
      end
      post ':id/merge_requests/:merge_request_iid/pipelines', urgency: :low, feature_category: :pipeline_composition do
        pipeline = nil
        merge_request = find_merge_request_with_access(params[:merge_request_iid])

        merge_request_params = { allow_duplicate: true }

        service = ::MergeRequests::CreatePipelineService.new(
          project: user_project, current_user: current_user, params: merge_request_params
        )

        if params[:async]
          service.execute_async(merge_request)
        else
          pipeline = service.execute(merge_request).payload
        end

        if params[:async]
          status :accepted
        elsif pipeline.nil?
          not_allowed!
        elsif pipeline.persisted?
          status :ok
          present pipeline, with: ::API::Entities::Ci::Pipeline
        else
          render_validation_error!(pipeline)
        end
      end

      desc 'Update merge request' do
        detail 'Updates an existing merge request. You can change the target branch, title, or even close the merge request.'
        success Entities::MergeRequest
        failure [
          { code: 400, message: 'Bad request' },
          { code: 404, message: 'Not found' },
          { code: 409, message: 'Conflict' },
          { code: 422, message: 'Unprocessable entity' }
        ]
        tags %w[merge_requests]
      end
      params do
        optional :title, type: String, allow_blank: false, desc: 'The title of the merge request.'
        optional :target_branch, type: String, allow_blank: false, desc: 'The target branch.'
        optional :state_event, type: String,
          values: %w[close reopen],
          desc: 'New state (close/reopen).'
        optional :discussion_locked, type: Boolean,
          desc: 'Flag indicating if the merge request’s discussion is locked. If the discussion is locked only project members can add, edit or resolve comments.'

        use :optional_params
        at_least_one_of(*::API::MergeRequests.update_params_at_least_one_of)
      end
      put ':id/merge_requests/:merge_request_iid', feature_category: :code_review_workflow, urgency: :low do
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
        detail 'Accept and merge changes submitted with the merge request using this API.'
        success Entities::MergeRequest
        failure [
          { code: 400, message: 'Bad request' },
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' },
          { code: 405, message: 'Method not allowed' },
          { code: 409, message: 'Conflict' },
          { code: 422, message: 'Unprocessable entity' }
        ]
        tags %w[merge_requests]
      end
      params do
        optional :merge_commit_message, type: String, desc: 'Custom merge commit message.'
        optional :squash_commit_message, type: String, desc: 'Custom squash commit message.'
        optional :should_remove_source_branch, type: Boolean,
          desc: 'If `true`, removes the source branch.'
        optional :merge_when_pipeline_succeeds, type: Boolean,
          desc: 'If `true`, the merge request is merged when the pipeline succeeds.'
        optional :sha, type: String, desc: 'If present, then this SHA must match the HEAD of the source branch, otherwise the merge fails.'
        optional :squash, type: Grape::API::Boolean, desc: 'If `true`, the commits are squashed into a single commit on merge.'

        use :optional_merge_params
      end
      put ':id/merge_requests/:merge_request_iid/merge', feature_category: :code_review_workflow, urgency: :low do
        Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/4796')

        merge_request = find_project_merge_request(params[:merge_request_iid])

        # Merge request can not be merged because the user doesn't have
        #   permissions to push into target branch.
        unauthorized! unless merge_request.can_be_merged_by?(current_user)

        merge_when_pipeline_succeeds = to_boolean(params[:merge_when_pipeline_succeeds])
        automatically_mergeable = automatically_mergeable?(merge_when_pipeline_succeeds, merge_request)
        immediately_mergeable = immediately_mergeable?(merge_when_pipeline_succeeds, merge_request)

        not_allowed! if !immediately_mergeable && !automatically_mergeable

        render_api_error!('Branch cannot be merged', 422) unless automatically_mergeable || merge_request.mergeable?(skip_ci_check: automatically_mergeable)

        check_sha_param!(params, merge_request)

        merge_request.update(squash: params[:squash]) if params[:squash]

        merge_params = HashWithIndifferentAccess.new(
          commit_message: params[:merge_commit_message],
          squash_commit_message: params[:squash_commit_message],
          should_remove_source_branch: params[:should_remove_source_branch],
          sha: params[:sha] || merge_request.diff_head_sha
        ).merge(ci_params).compact

        if immediately_mergeable
          ::MergeRequests::MergeService
            .new(project: merge_request.target_project, current_user: current_user, params: merge_params)
            .execute(merge_request)
        elsif automatically_mergeable
          AutoMergeService.new(merge_request.target_project, current_user, merge_params)
            .execute(merge_request, merge_request.default_auto_merge_strategy)
        end

        if immediately_mergeable && !merge_request.merged?
          render_api_error!("Branch cannot be merged", 422)
        else
          present merge_request, with: Entities::MergeRequest, current_user: current_user, project: user_project
        end
      end

      desc 'Returns the up to date merge-ref HEAD commit' do
        detail 'Returns the up to date merge-ref HEAD commit'
        failure [
          { code: 400, message: 'Bad request' }
        ]
        tags %w[merge_requests]
      end
      get ':id/merge_requests/:merge_request_iid/merge_ref', feature_category: :code_review_workflow do
        merge_request = find_project_merge_request(params[:merge_request_iid])

        result = ::MergeRequests::MergeabilityCheckService.new(merge_request).execute(recheck: true)

        if result.success?
          present :commit_id, result.payload.dig(:merge_ref_head, :commit_id)
        else
          render_api_error!(result.message, 400)
        end
      end

      desc 'Cancel Merge When Pipeline Succeeds' do
        detail 'Cancel merge if "Merge When Pipeline Succeeds" is enabled'
        success Entities::MergeRequest
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' },
          { code: 405, message: 'Method not allowed' },
          { code: 406, message: 'Not acceptable' }
        ]
        tags %w[merge_requests]
      end
      post ':id/merge_requests/:merge_request_iid/cancel_merge_when_pipeline_succeeds', feature_category: :code_review_workflow do
        merge_request = find_project_merge_request(params[:merge_request_iid])

        unauthorized! unless merge_request.can_cancel_auto_merge?(current_user)

        AutoMergeService.new(merge_request.target_project, current_user).cancel(merge_request)
      end

      desc 'Rebase a merge request' do
        detail 'Automatically rebase the `source_branch` of the merge request against its `target_branch`. This feature was added in GitLab 11.6'
        failure [
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' },
          { code: 409, message: 'Conflict' }
        ]
        tags %w[merge_requests]
      end
      params do
        optional :skip_ci, type: Boolean, desc: 'Set to true to skip creating a CI pipeline.'
      end
      put ':id/merge_requests/:merge_request_iid/rebase', feature_category: :code_review_workflow, urgency: :low do
        merge_request = find_project_merge_request(params[:merge_request_iid])

        authorize_merge_request_rebase!(merge_request)

        merge_request.rebase_async(current_user.id, skip_ci: params[:skip_ci])

        status :accepted
        present rebase_in_progress: merge_request.rebase_in_progress?
      rescue ::MergeRequest::RebaseLockTimeout => e
        render_api_error!(e.message, 409)
      end
      desc 'List issues that close on merge' do
        detail 'Get all the issues that would be closed by merging the provided merge request.'
        success Entities::MRNote
        failure [
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[merge_requests]
      end
      params do
        use :pagination
      end
      get ':id/merge_requests/:merge_request_iid/closes_issues', feature_category: :code_review_workflow, urgency: :low do
        merge_request = find_merge_request_with_access(params[:merge_request_iid])
        issues = ::Kaminari.paginate_array(merge_request.visible_closing_issues_for(current_user))
        issues = paginate(issues)

        external_issues, internal_issues = issues.partition { |issue| issue.is_a?(ExternalIssue) }

        data = Entities::IssueBasic.represent(internal_issues, current_user: current_user)
        data += Entities::ExternalIssue.represent(external_issues, current_user: current_user)

        data.as_json
      end

      desc 'List issues related to merge request' do
        detail 'Get all the related issues from title, description, commits, comments and discussions of the merge request.'
        failure [
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[merge_requests]
      end
      params do
        use :pagination
      end
      get ':id/merge_requests/:merge_request_iid/related_issues', feature_category: :code_review_workflow, urgency: :low do
        merge_request = find_merge_request_with_access(params[:merge_request_iid])
        issues = ::Kaminari.paginate_array(merge_request.related_issues(current_user))
        issues = paginate(issues)

        external_issues, internal_issues = issues.partition { |issue| issue.is_a?(ExternalIssue) }

        data = Entities::IssueBasic.represent(internal_issues, current_user: current_user)
        data += Entities::ExternalIssue.represent(external_issues, current_user: current_user)

        data.as_json
      end
    end
  end
end
