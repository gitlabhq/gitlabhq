# frozen_string_literal: true

module API
  class MergeRequests < ::API::Base
    include ::API::Concerns::McpAccess
    include APIGuard
    include PaginationParams
    include Helpers::Unidiff

    helpers ::API::Helpers::HeadersHelpers
    helpers ::API::Helpers::MilestonesHelpers

    CONTEXT_COMMITS_POST_LIMIT = 20

    before { authenticate_non_get! }

    allow_mcp_access_read
    allow_mcp_access_create
    allow_access_with_scope :ai_workflows, if: ->(request) do
      request.get? || request.head? || mr_update?(request) || mr_create?(request)
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

      # Overridden in EE
      def validate_immediate_merge!(merge_request); end
    end

    def self.mr_update?(request)
      request.put? && request.path.match?(%r{/api/v\d+/projects/[^/]+/merge_requests/\d+$})
    end

    def self.mr_create?(request)
      request.post? && request.path.match?(%r{/api/v\d+/projects/[^/]+/merge_requests$})
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
        milestone
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
        args[:sort] = "#{args[:order_by]}_#{args[:sort]}"
        args[:scope] = args[:scope].underscore if args[:scope]

        parent_type = args[:project_id] ? :project : :group
        args[:"attempt_#{parent_type}_search_optimizations"] = true

        finder = MergeRequestsFinder.new(current_user, args)
        merge_requests = paginate(finder.execute, skip_default_order: finder.group_mr_in_optimization_applied?)
                           .preload(:source_project, :target_project)

        return merge_requests if args[:view] == 'simple'

        merge_requests
          .with_api_entity_associations
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def render_merge_requests(merge_requests, options, skip_cache: false, ttl: 8.hours)
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
          expires_in: ttl,
          cache_context: cache_context,
          **options
      end

      def merge_request_pipelines_with_access
        mr = find_merge_request_with_access(params[:merge_request_iid])
        ::Ci::PipelinesForMergeRequestFinder.new(mr, current_user).execute
      end

      def pipeline_allows_merge?(merge_request)
        (!merge_request.pipeline_creating? && !merge_request.diff_head_pipeline) ||
          merge_request.diff_head_pipeline_success?
      end

      def execute_merge(merge_request, auto_merge, merge_params)
        if auto_merge
          auto_merge_service = AutoMergeService.new(merge_request.target_project, current_user, merge_params)
          preferred_strategy = auto_merge_service.preferred_strategy(merge_request)

          if preferred_strategy
            auto_merge_service.execute(merge_request, preferred_strategy)
          elsif pipeline_allows_merge?(merge_request)
            execute_immediate_merge!(merge_request, merge_params)
          else
            not_allowed!
          end
        elsif merge_request.mergeable?
          execute_immediate_merge!(merge_request, merge_params)
        else
          not_allowed!
        end
      end

      def execute_immediate_merge!(merge_request, merge_params)
        validate_immediate_merge!(merge_request)

        render_api_error!('Branch cannot be merged', 422) unless merge_request.mergeable?

        ::MergeRequests::MergeService
          .new(project: merge_request.target_project, current_user: current_user, params: merge_params)
          .execute(merge_request)

        render_api_error!('Branch cannot be merged', 422) unless merge_request.merged?
      end

      def build_merge_params(merge_request)
        check_sha_param!(params, merge_request)

        merge_request.update(squash: params[:squash]) if params[:squash]

        HashWithIndifferentAccess.new(
          commit_message: params[:merge_commit_message],
          squash_commit_message: params[:squash_commit_message],
          should_remove_source_branch: params[:should_remove_source_branch],
          sha: params[:sha] || merge_request.diff_head_sha
        ).merge(ci_params).compact
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

      params :merge_requests_params do
        use :merge_requests_base_params
        use :optional_merge_requests_search_params
        use :pagination
      end
    end

    resource :merge_requests do
      desc 'List all merge requests' do
        detail 'Lists all merge requests accessible to the authenticated user. By default, returns only merge ' \
          'requests created by the current user. Use `scope=all` to get all merge requests.'
        success Entities::MergeRequestBasic
        is_array true
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 422, message: 'Unprocessable entity' }
        ]
        tags %w[merge_requests]
      end
      params do
        use :merge_requests_params
        use :optional_scope_param
        optional :non_archived, type: Boolean,
          default: false,
          desc: 'Returns merge requests from non archived projects only.'
      end
      route_setting :authorization, permissions: :read_merge_request, boundary_type: :user
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
      desc 'List all group merge requests' do
        detail 'Lists all merge requests for a specified group and any subgroups.'
        success Entities::MergeRequestBasic
        is_array true
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
      route_setting :authorization, permissions: :read_merge_request, boundary_type: :group
      get ":id/merge_requests", feature_category: :code_review_workflow, urgency: :low do
        validate_search_rate_limit! if declared_params[:search].present?
        merge_requests = find_merge_requests(group_id: user_group.id, include_subgroups: true)
        options = serializer_options_for(merge_requests).merge(group: user_group)

        unless options[:skip_merge_status_recheck]
          batch_process_mergeability_checks(merge_requests)

          # NOTE: skipping individual mergeability checks in the presenter
          options[:skip_merge_status_recheck] = true
        end

        unless Feature.enabled?(:cache_list_mr_on_group_api_responses, user_group)
          present merge_requests, options
          next
        end

        skip_cache = declared_params[:with_labels_details] == true || !current_user&.bot?

        render_merge_requests(merge_requests, options, skip_cache: skip_cache, ttl: 30.minutes)
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
          optional :milestone_id, type: Integer, desc: 'The global ID of a milestone to assign the merge request to.'
          optional :milestone, type: String, limit: 255,
            desc: 'The title of a project or ancestor-group milestone to assign the merge request to. ' \
              'Mutually exclusive with `milestone_id`.'
          mutually_exclusive :milestone_id, :milestone
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

      desc 'List all project merge requests' do
        detail 'Lists all project merge requests.'
        success Entities::MergeRequestBasic
        is_array true
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
      route_setting :authentication, job_token_allowed: true
      route_setting :authorization, permissions: :read_merge_request,
        boundary_type: :project,
        job_token_policies: :read_merge_requests,
        allow_public_access_for_enabled_project_features: [:repository, :merge_requests]
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

      desc 'Create a merge request' do
        detail 'Creates a merge request for a project.'
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
      route_setting :mcp, tool_name: :create_merge_request, params: Helpers::MergeRequestsHelpers.create_merge_request_mcp_params,
        annotations: { readOnlyHint: false, destructiveHint: false }, resource_name: "project"
      route_setting :authorization, permissions: :create_merge_request, boundary_type: :project
      post ":id/merge_requests", feature_category: :code_review_workflow, urgency: :low do
        Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/20770')

        authorize! :create_merge_request_from, user_project

        Labkit::UserExperienceSli.start(:create_merge_request)

        mr_params = declared_params(include_missing: false)
        resolve_milestone_title!(user_project, mr_params)
        mr_params[:force_remove_source_branch] = mr_params.delete(:remove_source_branch)
        mr_params = convert_parameters_from_legacy_format(mr_params)
        validator = ::Gitlab::Auth::ScopeValidator.new(current_user, Gitlab::Auth::RequestAuthenticator.new(request))
        mr_params[:scope_validator] ||= validator

        begin
          merge_request = ::MergeRequests::CreateService
                            .new(project: user_project, current_user: current_user, params: mr_params)
                            .execute
        rescue QuickActions::InterpretService::QuickActionsNotAllowedError => error
          forbidden!(error.message)
        end
        handle_merge_request_errors!(merge_request)

        present merge_request, with: Entities::MergeRequest, current_user: current_user, project: user_project
      end

      desc 'Delete a merge request' do
        detail 'Deletes a specified merge request for a project. Administrators and project Owners only.'
        success code: 204
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
      route_setting :authorization, permissions: :delete_merge_request, boundary_type: :project
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
      desc 'Retrieve a merge request' do
        detail 'Retrieves a merge request for a specified project.'

        success Entities::MergeRequest
        failure [
          { code: 404, message: 'Not found' }
        ]
        tags %w[merge_requests]
      end
      route_setting :mcp, tool_name: :get_merge_request, params: [:id, :merge_request_iid], resource_name: "merge request"
      route_setting :authentication, job_token_allowed: true
      route_setting :authorization, permissions: :read_merge_request,
        boundary_type: :project,
        job_token_policies: :read_merge_requests,
        allow_public_access_for_enabled_project_features: [:repository, :merge_requests]
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

      desc 'Retrieve merge request participants' do
        detail 'Retrieves participants for a specified merge request.'
        success Entities::UserBasic
        is_array true
        failure [
          { code: 404, message: 'Not found' }
        ]
        tags %w[merge_requests]
      end
      route_setting :authorization, permissions: :read_merge_request_participant, boundary_type: :project
      get ':id/merge_requests/:merge_request_iid/participants', feature_category: :code_review_workflow, urgency: :low do
        merge_request = find_merge_request_with_access(params[:merge_request_iid])

        participants = ::Kaminari.paginate_array(merge_request.participants(current_user))

        present paginate(participants), with: Entities::UserBasic
      end

      desc 'Retrieve merge request reviewers' do
        detail 'Retrieves reviewers for a specified merge request.'
        success Entities::MergeRequestReviewer
        is_array true
        failure [
          { code: 404, message: 'Not found' }
        ]
        tags %w[merge_requests]
      end
      route_setting :authorization, permissions: :read_merge_request_reviewer, boundary_type: :project
      get ':id/merge_requests/:merge_request_iid/reviewers', feature_category: :code_review_workflow, urgency: :low do
        merge_request = find_merge_request_with_access(params[:merge_request_iid])

        reviewers = ::Kaminari.paginate_array(merge_request.merge_request_reviewers)

        present paginate(reviewers), with: Entities::MergeRequestReviewer
      end

      desc 'Retrieve merge request commits' do
        detail 'Retrieves commits for a specified merge request.'
        success Entities::Commit
        is_array true
        failure [
          { code: 404, message: 'Not found' }
        ]
        tags %w[merge_requests]
      end
      params do
        requires :merge_request_iid, type: Integer, desc: 'The internal ID of the merge request.'
        use :pagination
      end
      route_setting :mcp, tool_name: :get_merge_request_commits, params: [:id, :merge_request_iid, :per_page, :page], resource_name: "merge request"
      route_setting :authorization, permissions: :read_merge_request_commit, boundary_type: :project
      get ':id/merge_requests/:merge_request_iid/commits', feature_category: :code_review_workflow, urgency: :low do
        merge_request = find_merge_request_with_access(params[:merge_request_iid])
        merge_request_diff = merge_request.merge_request_diff

        page = params[:page] > 0 ? params[:page] : 1
        per_page = params[:per_page] > 0 ? params[:per_page] : Kaminari.config.default_per_page
        limit = [per_page, Kaminari.config.max_per_page].min

        gitaly_commits = merge_request_diff.commits(limit: limit, page: page, load_from_gitaly: true)

        paginatable_array = Kaminari.paginate_array(gitaly_commits, total_count: merge_request_diff.commits_count).page(page).per(limit)
        commits = paginate(paginatable_array)

        present commits, with: Entities::Commit
      end

      desc 'List all context commits for a merge request' do
        detail 'Lists all context commits for a specified merge request.'
        success Entities::Commit
        is_array true
        failure [
          { code: 404, message: 'Not found' }
        ]
        tags %w[merge_requests]
      end
      route_setting :authorization, permissions: :read_merge_request_context_commit, boundary_type: :project
      get ':id/merge_requests/:merge_request_iid/context_commits', feature_category: :code_review_workflow, urgency: :low do
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
      desc 'Create context commits for a merge request' do
        detail 'Creates context commits for a specified merge request.'
        success Entities::Commit
        is_array true
        failure [
          { code: 400, message: 'Bad request' },
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[merge_requests]
      end
      route_setting :authorization, permissions: :create_merge_request_context_commit, boundary_type: :project
      post ':id/merge_requests/:merge_request_iid/context_commits', feature_category: :code_review_workflow, urgency: :low do
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
      desc 'Delete context commits from a merge request' do
        detail 'Deletes specified context commits from a merge request.'
        success code: 204
        failure [
          { code: 400, message: 'Bad request' },
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[merge_requests]
      end
      route_setting :authorization, permissions: :delete_merge_request_context_commit, boundary_type: :project
      delete ':id/merge_requests/:merge_request_iid/context_commits', feature_category: :code_review_workflow, urgency: :low do
        commit_ids = params[:commits]
        merge_request = find_merge_request_with_access(params[:merge_request_iid])

        authorize!(:update_merge_request, merge_request)
        project = merge_request.target_project
        commits = project.repository.commits_by(oids: commit_ids)

        if commits.size != commit_ids.size
          render_api_error!("One or more context commits' sha is not valid.", 400)
        end

        MergeRequestContextCommit.delete_bulk(merge_request, commits)
        status 204
      end

      desc 'Retrieve merge request changes' do
        detail 'Retrieves changes for a specified merge request.'
        success Entities::MergeRequestChanges
        failure [
          { code: 404, message: 'Not found' }
        ]
        tags %w[merge_requests]
      end
      params do
        use :with_unidiff
      end
      route_setting :authorization, permissions: :read_merge_request_diff, boundary_type: :project
      get ':id/merge_requests/:merge_request_iid/changes', feature_category: :code_review_workflow, urgency: :low do
        merge_request = find_merge_request_with_access(params[:merge_request_iid])

        present merge_request,
          with: Entities::MergeRequestChanges,
          current_user: current_user,
          project: user_project,
          access_raw_diffs: to_boolean(params.fetch(:access_raw_diffs, false)),
          enable_unidiff: declared_params[:unidiff]
      end

      desc 'List all merge request diffs' do
        detail 'Lists all merge request diffs.'
        success Entities::Diff
        is_array true
        failure [
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[merge_requests]
      end
      params do
        requires :merge_request_iid, type: Integer, desc: 'The internal ID of the merge request.'
        use :pagination
        use :with_unidiff
      end
      route_setting :mcp, tool_name: :get_merge_request_diffs, params: [:id, :merge_request_iid, :per_page, :page], resource_name: "merge request"
      route_setting :authorization, permissions: :read_merge_request_diff, boundary_type: :project
      get ':id/merge_requests/:merge_request_iid/diffs', feature_category: :code_review_workflow, urgency: :low do
        merge_request = find_merge_request_with_access(params[:merge_request_iid])

        diffs = paginate(
          merge_request.merge_request_diff.paginated_diffs(params[:page], params[:per_page], { expanded: true }),
          skip_pagination_check: true
        ).diffs
        filtered_diffs = filter_diffs_for_mcp(diffs, user_project)

        present filtered_diffs, with: Entities::Diff, enable_unidiff: declared_params[:unidiff]
      end

      desc 'Retrieve merge request raw diffs' do
        detail 'Retrieves the raw diffs of the files changed in a merge request.'
        success code: 200
        failure [
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[merge_requests]
      end
      route_setting :authorization, permissions: :read_merge_request_raw_diff, boundary_type: :project
      get ':id/merge_requests/:merge_request_iid/raw_diffs', feature_category: :code_review_workflow, urgency: :low do
        merge_request = find_merge_request_with_access(params[:merge_request_iid])

        no_cache_headers

        send_git_diff(merge_request.project.repository, merge_request.diff_refs)
      end

      desc 'List all merge request pipelines' do
        detail 'Lists all merge request pipelines.'
        success Entities::Ci::PipelineBasic
        is_array true
        failure [
          { code: 404, message: 'Not found' }
        ]
        tags %w[merge_requests]
      end
      params do
        requires :merge_request_iid, type: Integer, desc: 'The internal ID of the merge request.'
      end
      route_setting :mcp, tool_name: :get_merge_request_pipelines, params: [:id, :merge_request_iid, :per_page, :page], resource_name: "merge request"
      route_setting :authorization, permissions: :read_merge_request_pipeline, boundary_type: :project
      get ':id/merge_requests/:merge_request_iid/pipelines', urgency: :low, feature_category: :pipeline_composition do
        pipelines = merge_request_pipelines_with_access
        present paginate(pipelines), with: Entities::Ci::PipelineBasic
      end

      desc 'Create a merge request pipeline' do
        detail 'Creates a merge request pipeline. Pipelines created with this operation must configure ' \
          '`.gitlab-ci.yml` with `only: [merge_requests]` to create jobs.'
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
      route_setting :authorization, permissions: :create_merge_request_pipeline, boundary_type: :project
      post ':id/merge_requests/:merge_request_iid/pipelines', urgency: :low, feature_category: :pipeline_composition do
        pipeline = nil
        merge_request = find_merge_request_with_access(params[:merge_request_iid])

        merge_request_params = { allow_duplicate: true }

        service = ::MergeRequests::CreatePipelineService.new(
          project: user_project, current_user: current_user, params: merge_request_params
        )

        if params[:async]
          service.execute_async(merge_request)

          status :accepted
        else
          pipeline = service.execute(merge_request).payload
          if pipeline.nil?
            not_allowed!
          elsif pipeline.persisted?
            status :ok
            present pipeline, with: ::API::Entities::Ci::Pipeline
          else
            render_validation_error!(pipeline)
          end
        end
      end

      desc 'Update a merge request' do
        detail 'Updates a merge request for a specified project.'
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
      route_setting :authorization, permissions: :update_merge_request, boundary_type: :project
      put ':id/merge_requests/:merge_request_iid', feature_category: :code_review_workflow, urgency: :low do
        Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/20772')

        merge_request = find_merge_request_with_access(params.delete(:merge_request_iid), :update_merge_request)

        mr_params = declared_params(include_missing: false)
        resolve_milestone_title!(user_project, mr_params)
        mr_params[:force_remove_source_branch] = mr_params.delete(:remove_source_branch) if mr_params.has_key?(:remove_source_branch)
        mr_params = convert_parameters_from_legacy_format(mr_params)
        mr_params[:use_specialized_service] = true
        validator = ::Gitlab::Auth::ScopeValidator.new(current_user, Gitlab::Auth::RequestAuthenticator.new(request))
        mr_params[:scope_validator] ||= validator

        begin
          merge_request = ::MergeRequests::UpdateService
            .new(project: user_project, current_user: current_user, params: mr_params)
            .execute(merge_request)
        rescue QuickActions::InterpretService::QuickActionsNotAllowedError => error
          forbidden!(error.message)
        end

        handle_merge_request_errors!(merge_request)

        present merge_request, with: Entities::MergeRequest, current_user: current_user, project: user_project
      end

      desc 'Merge a merge request' do
        detail 'Merges a merge request. Accepts and merges changes submitted with the merge request.'
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
          desc: 'Deprecated: Use auto_merge instead.'
        optional :auto_merge, type: Boolean,
          desc: 'If `true`, the merge request is set to auto merge.'
        optional :sha, type: String, desc: 'If present, then this SHA must match the HEAD of the source branch, otherwise the merge fails.'
        optional :squash, type: Grape::API::Boolean, desc: 'If `true`, the commits are squashed into a single commit on merge.'

        use :optional_merge_params
      end
      route_setting :authorization, permissions: :merge_merge_request, boundary_type: :project
      put ':id/merge_requests/:merge_request_iid/merge', feature_category: :code_review_workflow, urgency: :low do
        Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/4796')

        merge_request = find_project_merge_request(params[:merge_request_iid])

        if user_project.namespace.require_sha_for_merge? && !params[:sha].present?
          render_api_error!("SHA must be provided when merging", 400)
        end

        # Merge request can not be merged because the user doesn't have
        #   permissions to push into target branch.
        unauthorized! unless merge_request.can_be_merged_by?(current_user)

        auto_merge = to_boolean(params[:merge_when_pipeline_succeeds]) || to_boolean(params[:auto_merge])

        merge_params = build_merge_params(merge_request)

        execute_merge(merge_request, auto_merge, merge_params)

        present merge_request, with: Entities::MergeRequest, current_user: current_user, project: user_project
      end

      desc 'Merge to default merge ref path' do
        detail 'Merges the changes between the merge request source and target branches into the ' \
          '`refs/merge-requests/:iid/merge` ref, of the target project repository, if possible. This ref has the state ' \
          'the target branch would have if a regular merge action was taken.'
        success code: 200
        failure [
          { code: 400, message: 'Bad request' }
        ]
        tags %w[merge_requests]
      end
      route_setting :authorization, permissions: :read_merge_request_merge_ref, boundary_type: :project
      get ':id/merge_requests/:merge_request_iid/merge_ref', feature_category: :code_review_workflow do
        merge_request = find_project_merge_request(params[:merge_request_iid])

        result = ::MergeRequests::MergeabilityCheckService.new(merge_request).execute(recheck: true)

        if result.success?
          present :commit_id, result.payload.dig(:merge_ref_head, :commit_id)
        else
          render_api_error!(result.message, 400)
        end
      end

      desc 'Cancel merge when pipeline succeeds' do
        detail 'Cancels an automatic merge for a merge request that has been set to merge when the pipeline succeeds.'
        success Entities::MergeRequest
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' },
          { code: 405, message: 'Method not allowed' },
          { code: 406, message: 'Not acceptable' }
        ]
        tags %w[merge_requests]
      end
      route_setting :authorization, permissions: :cancel_merge_merge_request, boundary_type: :project
      post ':id/merge_requests/:merge_request_iid/cancel_merge_when_pipeline_succeeds', feature_category: :code_review_workflow do
        merge_request = find_project_merge_request(params[:merge_request_iid])

        unauthorized! unless merge_request.can_cancel_auto_merge?(current_user)

        AutoMergeService.new(merge_request.target_project, current_user).cancel(merge_request)
      end

      desc 'Rebase a merge request' do
        detail 'Rebases a merge request. Automatically rebases the `source_branch` of the merge request against its ' \
          '`target_branch`.'
        success code: 202
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
      route_setting :authorization, permissions: :rebase_merge_request, boundary_type: :project
      put ':id/merge_requests/:merge_request_iid/rebase', feature_category: :code_review_workflow, urgency: :low do
        merge_request = find_project_merge_request(params[:merge_request_iid])

        authorize_merge_request_rebase!(merge_request)

        merge_request.rebase_async(current_user.id, skip_ci: params[:skip_ci])

        status :accepted
        present rebase_in_progress: merge_request.rebase_in_progress?
      rescue ::MergeRequest::RebaseLockTimeout => e
        render_api_error!(e.message, 409)
      end

      desc 'List all issues that close on merge' do
        detail 'Lists all issues that close on merge.'
        success Entities::MRNote
        is_array true
        failure [
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[merge_requests]
      end
      params do
        use :pagination
      end
      route_setting :authorization, permissions: :read_merge_request_closes_issue, boundary_type: :project
      get ':id/merge_requests/:merge_request_iid/closes_issues', feature_category: :code_review_workflow, urgency: :low do
        merge_request = find_merge_request_with_access(params[:merge_request_iid])
        issues = ::Kaminari.paginate_array(merge_request.visible_closing_issues_for(current_user))
        issues = paginate(issues)

        external_issues, internal_issues = issues.partition { |issue| issue.is_a?(ExternalIssue) }

        data = Entities::IssueBasic.represent(internal_issues, current_user: current_user)
        data += Entities::ExternalIssue.represent(external_issues, current_user: current_user)

        data.as_json
      end

      desc 'List all issues related to the merge request' do
        detail 'Lists all issues related to the merge request.'
        success code: 200
        is_array true
        failure [
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not found' }
        ]
        tags %w[merge_requests]
      end
      params do
        use :pagination
      end
      route_setting :authorization, permissions: :read_merge_request_related_issue, boundary_type: :project
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
