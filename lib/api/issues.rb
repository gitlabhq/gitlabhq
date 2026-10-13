# frozen_string_literal: true

module API
  class Issues < ::API::Base
    include ::API::Concerns::AiWorkflowsAccess
    include ::API::Concerns::McpAccess
    include APIGuard
    include PaginationParams

    allow_ai_workflows_access
    allow_mcp_access_read
    allow_mcp_access_create

    rescue_from ::Issuable::Callbacks::Base::Error do |e|
      error!({ 'message' => e.message }, 400)
    end

    helpers Helpers::IssuesHelpers
    helpers Helpers::MilestonesHelpers
    helpers Helpers::Authz::PostfilteringHelpers
    helpers SpammableActions::CaptchaCheck::RestApiActionsSupport

    before { authenticate_non_get! }

    feature_category :team_planning
    urgency :low

    helpers do
      params :negatable_issue_filter_params do
        optional :labels, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce, desc: 'Comma-separated list of label names.'
        optional :milestone, type: String, desc: 'Milestone title.'
        optional :milestone_id, types: String, values: %w[Any None Upcoming Started],
          desc: 'Return issues assigned to milestones without the specified timebox value.'
        mutually_exclusive :milestone_id, :milestone

        optional :iids, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce, desc: 'Internal IDs of issues to exclude.'

        optional :author_id, type: Integer, desc: 'Return issues not authored by the user with the given ID.'
        optional :author_username, type: String, desc: 'Return issues not authored by the user with the given username.'
        mutually_exclusive :author_id, :author_username

        optional :assignee_id, type: Integer, desc: 'Return issues not assigned to the user with the given ID.'
        optional :assignee_username, type: Array[String], check_assignees_count: true,
          coerce_with: Validations::Validators::CheckAssigneesCount.coerce,
          desc: 'Return issues not assigned to the user with the given username.'
        mutually_exclusive :assignee_id, :assignee_username

        use :negatable_issue_filter_params_ee
      end

      params :issues_stats_params do
        optional :labels, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce, desc: 'Comma-separated list of label names. `None` means no labels are assigned. `Any` means at least one label is assigned. `No+Label` (deprecated) means no labels are assigned. Set to an empty string to unassign all labels. If a label does not already exist, this creates a new project label and assigns it to the issue. Predefined names are case-insensitive.'
        optional :milestone, type: String, desc: 'Milestone title. `None` lists all issues with no milestone. `Any` lists all issues that have an assigned milestone. Support for `None` and `Any` is [planned for removal](https://gitlab.com/gitlab-org/gitlab/-/issues/336044). Use the `milestone_id` attribute instead.'
        # 'milestone_id' only accepts wildcard values 'Any', 'None', 'Upcoming', 'Started'
        # the param has '_id' in the name to keep consistency (ex. assignee_id accepts id and wildcard values).
        optional :milestone_id, types: String, values: %w[Any None Upcoming Started],
          desc: 'Return issues assigned to milestones with a given timebox value. `None` lists all issues with no milestone. `Any` lists all issues that have an assigned milestone. `Upcoming` lists all issues assigned to milestones due in the future. `Started` lists all issues assigned to open, started milestones. The logic for `Upcoming` and `Started` differs from the logic used in the [GraphQL API](https://docs.gitlab.com/user/project/milestones/#special-milestone-filters).'
        optional :iids, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce, desc: 'Return only the issues having the given `iid`.'
        optional :search, type: String, desc: 'Search issues against their `title` and `description`.'
        optional :in, type: String, desc: 'Modify the scope of the `search` attribute to `title`, `description`, or `title,description`. If omitted, defaults to `title,description`.'
        mutually_exclusive :milestone_id, :milestone

        optional :author_id, type: Integer, desc: 'Return issues created by the given user ID. Combine with `scope=all` or `scope=assigned_to_me`.'
        optional :author_username, type: String, desc: 'Return issues created by the given `username`.'
        mutually_exclusive :author_id, :author_username

        optional :assignee_id, types: [Integer, String], integer_none_any: true,
          desc: 'Return issues assigned to the given user `id`. `None` returns unassigned issues and `Any` returns issues with an assignee.'
        optional :assignee_username, type: Array[String], check_assignees_count: true,
          coerce_with: Validations::Validators::CheckAssigneesCount.coerce,
          desc: 'Return issues assigned to the given username. In GitLab Community Edition, only a single value is accepted. Otherwise, an invalid parameter error is returned. When multiple usernames are given, only issues assigned to all of them are returned.'
        mutually_exclusive :assignee_id, :assignee_username

        optional :created_after, type: DateTime, desc: 'Return issues created on or after the specified time.'
        optional :created_before, type: DateTime, desc: 'Return issues created on or before the specified time.'
        optional :updated_after, type: DateTime, desc: 'Return issues updated on or after the specified time.'
        optional :updated_before, type: DateTime, desc: 'Return issues updated on or before the specified time.'

        optional :not, type: Hash, desc: 'Return issues that do not match the specified parameters.' do
          use :negatable_issue_filter_params
        end

        optional :scope, type: String, values: %w[created-by-me assigned-to-me created_by_me assigned_to_me all],
          desc: 'Return issues for the given scope.'
        optional :my_reaction_emoji, type: String, desc: 'Return issues reacted to by the authenticated user with the given `emoji`. `None` returns issues with no reaction and `Any` returns issues with at least one reaction.'
        optional :confidential, type: Boolean, desc: 'If `true`, returns only confidential issues. If `false`, returns only public issues.'

        use :issues_stats_params_ee
      end

      params :issues_params do
        optional :with_labels_details, type: Boolean, desc: 'If `true`, the response returns more details for each label in the labels field: `name`, `color`, `description`, `description_html`, `text_color`.', default: false
        optional :state, type: String, values: %w[opened closed all], default: 'all',
          desc: 'Filter issues by state.'
        optional :closed_by_id, type: Integer, desc: 'Return issues closed by the user with the given ID.'
        optional :order_by, type: String, values: Helpers::IssuesHelpers.sort_options, default: 'created_at',
          desc: 'Sort results by the specified field.'
        optional :sort, type: String, values: %w[asc desc], default: 'desc',
          desc: 'Sort results in ascending or descending order.'
        optional :due_date, type: String, values: %w[0 any today tomorrow overdue week month next_month_and_previous_two_weeks] << '',
          desc: 'Return issues that have no due date, are overdue, or whose due date is this week, this month, or between two weeks ago and next month.'
        optional :issue_type, type: String, values: ::WorkItems::TypesFramework::Provider.unfiltered_base_types_for_issues, desc: "The type of the issue. Accepts: #{::WorkItems::TypesFramework::Provider.unfiltered_base_types_for_issues.join(', ')}"
        use :issues_stats_params
        use :pagination
      end

      params :issue_params do
        optional :description, type: String, desc: 'Description of the issue. Limited to 1,048,576 characters.'
        optional :assignee_ids, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce, desc: 'IDs of the users to assign to the issue. Set to `0` or leave empty to unassign all assignees. Assigning more than one user is Premium and Ultimate only.'
        optional :assignee_id,  type: Integer, desc: 'ID of the user to assign the issue to. Available only on GitLab Free. Deprecated. Use `assignee_ids` instead.'
        optional :milestone_id, type: Integer, desc: 'Global ID of a milestone to assign to the issue. Set to `0` or leave empty to unassign the milestone.'
        optional :milestone, type: String, limit: 255,
          desc: 'The title of a project or ancestor-group milestone to assign the issue to.'
        mutually_exclusive :milestone_id, :milestone
        optional :labels, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce, desc: 'Comma-separated list of label names. `None` means no labels are assigned. `Any` means at least one label is assigned. `No+Label` (deprecated) means no labels are assigned. Set to an empty string to unassign all labels. If a label does not already exist, this creates a new project label and assigns it to the issue. Predefined names are case-insensitive.'
        optional :add_labels, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce, desc: 'Comma-separated label names to add to the issue. If a label does not already exist, this creates a new project label and assigns it to the issue.'
        optional :remove_labels, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce, desc: 'Comma-separated label names to remove from the issue.'
        optional :due_date, type: String, desc: 'Due date, in the format `YYYY-MM-DD`, for example `2016-03-11`.'
        optional :start_date, type: String, desc: 'Start date, in the format `YYYY-MM-DD`, for example `2016-03-11`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/238041) in GitLab 19.1.'
        optional :confidential, type: Boolean, desc: 'If `true`, the issue is confidential.', allow_blank: false
        optional :discussion_locked, type: Boolean, desc: "If `true`, locks the issue's discussion so only project members can add or edit comments."
        optional :issue_type, type: String, values: ::WorkItems::TypesFramework::Provider.unfiltered_base_types_for_issues, desc: "The type of the issue. Accepts: #{::WorkItems::TypesFramework::Provider.unfiltered_base_types_for_issues.join(', ')}"
        optional :severity, type: String, values: IssuableSeverity.severities.keys, desc: "The severity of the issue. Only applies to incidents. Accepts: #{IssuableSeverity.severities.keys.join(', ')}"

        use :optional_issue_params_ee
      end
    end

    desc 'Retrieve issues statistics for the currently authenticated user' do
      detail 'Retrieves statistics for issues accessible by the currently authenticated user. By default, ' \
        'returns only issues created by the current user. To get all issues, set the `scope` attribute to `all`.'
      success code: 200
      tags ['issues']
    end
    params do
      use :issues_stats_params
      optional :scope, type: String, values: %w[created_by_me assigned_to_me all], default: 'created_by_me',
        desc: 'Return issues for the given scope.'
    end
    route_setting :authorization, permissions: :read_issue_statistic, boundary_type: :user
    get '/issues_statistics' do
      authenticate! unless params[:scope] == 'all'
      validate_search_rate_limit! if declared_params[:search].present?

      present issues_statistics, with: Grape::Presenters::Presenter
    end

    resource :issues do
      desc 'List all issues for the currently authenticated user' do
        detail 'Lists all issues accessible by the currently authenticated user. By default, returns only issues ' \
          'created by the current user. To list all issues, use parameter `scope=all`.'
        success Entities::Issue
        tags ['issues']
      end
      params do
        use :issues_params
        optional :scope, type: String, values: %w[created-by-me assigned-to-me created_by_me assigned_to_me all], default: 'created_by_me',
          desc: 'Return issues for the given scope.'
        optional :non_archived, type: Boolean, default: true,
          desc: 'If `true`, returns only issues from non-archived projects. If `false`, returns issues from both archived and non-archived projects.'
      end
      route_setting :authorization, permissions: :read_issue, boundary_type: :user
      get do
        authenticate! unless params[:scope] == 'all'
        validate_search_rate_limit! if declared_params[:search].present?
        issues = paginate(find_issues)

        issues = filter_with_logging(
          collection: issues,
          filter_proc: -> { Ability.issues_readable_by_user(issues, current_user) },
          resource_type: 'api/issues'
        )

        options = {
          with: Entities::Issue,
          with_labels_details: declared_params[:with_labels_details],
          current_user: current_user,
          include_subscribed: false
        }

        present issues, **options
      end

      desc 'Retrieve an issue' do
        detail 'Retrieves a specified issue. Administrators only.'
        success Entities::Issue
        tags ['issues']
      end
      params do
        requires :id, type: String, desc: 'ID of the issue.'
      end
      route_setting :authorization, permissions: :read_issue, boundary_type: :instance, assignable_when: [:admin]
      get ":id" do
        authenticated_as_admin!
        issue = Issue.find(params['id'])

        present issue, with: Entities::Issue, current_user: current_user, project: issue.project
      end
    end

    params do
      requires :id, type: String, desc: 'ID or URL-encoded path of the group.'
    end
    resource :groups, requirements: ::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'List all issues for a group' do
        detail 'Lists all issues for a specified group. If the group is private, you must provide credentials to ' \
          'authorize. In most cases, you should authenticate with a personal access token.'
        tags ['groups']
        success Entities::Issue
      end
      params do
        use :issues_params
        optional :non_archived, type: Boolean, desc: 'If `true`, returns only issues from non-archived projects. If `false`, returns issues from both archived and non-archived projects.', default: true
      end
      route_setting :authorization, permissions: :read_issue, boundary_type: :group
      get ":id/issues" do
        validate_search_rate_limit! if declared_params[:search].present?
        issues = paginate(find_issues(group_id: user_group.id, include_subgroups: true))

        options = {
          with: Entities::Issue,
          with_labels_details: declared_params[:with_labels_details],
          current_user: current_user,
          include_subscribed: false,
          group: user_group
        }

        present issues, **options
      end

      desc 'Retrieve issues statistics for a group' do
        detail 'Retrieves statistics for issues in a specified group.'
        success code: 200
        tags ['groups']
      end
      params do
        use :issues_stats_params
      end
      route_setting :authorization, permissions: :read_issue_statistic, boundary_type: :group
      get ":id/issues_statistics" do
        validate_search_rate_limit! if declared_params[:search].present?

        present issues_statistics(group_id: user_group.id, include_subgroups: true), with: Grape::Presenters::Presenter
      end
    end

    params do
      requires :id, types: [String, Integer], desc: 'ID or URL-encoded path of the project.'
    end
    resource :projects, requirements: ::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      include TimeTrackingEndpoints

      desc 'List all project issues' do
        detail 'Lists all issues for a specified project. If the project is private, you need to provide credentials ' \
          'to authorize. In most cases, you should authenticate with a personal access token.'
        success Entities::Issue
        tags ['projects']
      end
      params do
        use :issues_params
        optional :cursor, type: String, desc: 'Cursor for obtaining the next set of records.'
      end
      route_setting :authentication, job_token_allowed: true
      route_setting :authorization,
        permissions: :read_issue,
        boundary_type: :project,
        job_token_policies: :read_work_items,
        allow_public_access_for_enabled_project_features: :issues
      get ":id/issues" do
        validate_search_rate_limit! if declared_params[:search].present?

        if declared_params[:order_by] && Issue.supported_keyset_orderings.keys
                                              .exclude?(declared_params[:order_by].to_sym)
          params.delete("pagination")
        end

        issues = find_issues(project_id: user_project.id)

        options = {
          with: Entities::Issue,
          with_labels_details: declared_params[:with_labels_details],
          current_user: current_user,
          project: user_project,
          include_subscribed: false
        }

        present paginate_with_strategies(issues), **options
      end

      desc 'Retrieve issues statistics for a project' do
        detail 'Retrieves statistics for issues in a specified project.'
        tags ['projects']
        success code: 200
      end
      params do
        use :issues_stats_params
      end
      route_setting :authorization, permissions: :read_issue_statistic, boundary_type: :project
      get ":id/issues_statistics" do
        validate_search_rate_limit! if declared_params[:search].present?

        present issues_statistics(project_id: user_project.id), with: Grape::Presenters::Presenter
      end

      desc 'Retrieve a project issue' do
        detail 'Retrieves a specified issue for a project. If the project is private or the issue is confidential, ' \
          'you need to provide credentials to authorize. In most cases, you should authenticate with a personal ' \
          'access token.'
        success Entities::Issue
        tags ['projects']
      end
      params do
        requires :issue_iid, type: Integer, desc: 'Internal ID of the issue.'
      end
      # Unlisted pending removal: superseded by get_work_item (https://gitlab.com/gitlab-org/gitlab/-/work_items/628333).
      route_setting :mcp, tool_name: :get_issue, toolset: :work_items, params: [:id, :issue_iid],
        resource_name: "issue", unlisted: true
      route_setting :authentication, job_token_allowed: true
      route_setting :authorization, permissions: :read_issue, boundary_type: :project, job_token_policies: :read_work_items, allow_public_access_for_enabled_project_features: :issues
      get ":id/issues/:issue_iid", as: :api_v4_project_issue do
        issue = find_project_issue(params[:issue_iid])
        present issue, with: Entities::Issue, current_user: current_user, project: user_project
      end

      desc 'Create an issue' do
        detail 'Creates an issue for a specified project.'
        success Entities::Issue
        tags ['projects']
      end
      params do
        requires :title, type: String, desc: 'Title of the issue.'
        optional :created_at, type: DateTime,
          desc: 'Date and time the issue was created. Requires administrator or project/group owner rights.'
        optional :merge_request_to_resolve_discussions_of, type: Integer,
          desc: 'Internal ID of a merge request for which to resolve discussions. This fills the issue with a default description and marks all discussions as resolved, unless a title or description is provided.'
        optional :discussion_to_resolve, type: String,
          desc: 'ID of a discussion to resolve. Use in combination with `merge_request_to_resolve_discussions_of`.'
        optional :iid, type: Integer,
          desc: 'Internal ID to assign to the new issue. Administrators or project owners only.'

        use :issue_params
      end
      # Unlisted pending removal: superseded by save_work_item (https://gitlab.com/gitlab-org/gitlab/-/work_items/625129).
      route_setting :mcp, tool_name: :create_issue, toolset: :work_items,
        params: Helpers::IssuesHelpers.create_issue_mcp_params,
        container_arguments: Helpers::IssuesHelpers.create_issue_mcp_container_arguments,
        annotations: { readOnlyHint: false, destructiveHint: false }, resource_name: "project", unlisted: true
      route_setting :authorization, permissions: :create_issue, boundary_type: :project
      post ':id/issues' do
        Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/21140')

        authorize! :create_issue, user_project

        issue_params = declared_params(include_missing: false)
        resolve_milestone_title!(user_project, issue_params)
        validator = ::Gitlab::Auth::ScopeValidator.new(current_user, Gitlab::Auth::RequestAuthenticator.new(request))
        issue_params = convert_parameters_from_legacy_format(issue_params).merge(scope_validator: validator)
        begin
          result = ::Issues::CreateService.new(container: user_project,
            current_user: current_user,
            params: issue_params).execute

          if result.success?
            present result[:issue], with: Entities::Issue, current_user: current_user, project: user_project
          elsif result[:issue]
            issue = result[:issue]

            with_captcha_check_rest_api(spammable: issue) do
              render_validation_error!(issue)
            end
          else
            render_api_error!(result.errors.join(', '), result.http_status || 422)
          end
        rescue ::ActiveRecord::RecordNotUnique
          render_api_error!('Duplicated issue', 409)
        rescue ::Issues::BaseService::EpicAssignmentError => error
          render_api_error!(error.message, 422)
        rescue QuickActions::InterpretService::QuickActionsNotAllowedError => error
          forbidden!(error.message)
        end
      end

      desc 'Update an issue' do
        detail 'Updates a specified issue for a project. This request is also used to close or reopen an issue using ' \
          'the `state_event` parameter. At least one of the following parameters is required for the request to be ' \
          'successful: `assignee_id`, `assignee_ids`, `confidential`, `created_at`, `description`, ' \
          '`discussion_locked`, `due_date`, `issue_type`, `labels`, `milestone_id`, `state_event`, `title`.'
        success Entities::Issue
        tags ['projects']
      end
      params do
        requires :issue_iid, type: Integer, desc: 'Internal ID of the issue.'
        optional :title, type: String, desc: 'Title of the issue.'
        optional :updated_at, type: DateTime,
          allow_blank: false,
          desc: 'Date and time the issue was updated. Administrators or project owners only. Empty or null values are not accepted.'
        optional :state_event, type: String, values: %w[reopen close], desc: 'Event to change the state of the issue.'
        use :issue_params

        at_least_one_of(*Helpers::IssuesHelpers.update_params_at_least_one_of)
      end
      route_setting :authorization, permissions: :update_issue, boundary_type: :project
      # rubocop: disable CodeReuse/ActiveRecord
      put ':id/issues/:issue_iid' do
        Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/20775')

        issue = user_project.issues.find_by!(iid: params.delete(:issue_iid))
        authorize! :update_issue, issue

        update_params = declared_params(include_missing: false)
        resolve_milestone_title!(user_project, update_params)

        validator = ::Gitlab::Auth::ScopeValidator.new(current_user, Gitlab::Auth::RequestAuthenticator.new(request))
        update_params = convert_parameters_from_legacy_format(update_params).merge(scope_validator: validator)

        begin
          issue = ::Issues::UpdateService.new(container: user_project,
            current_user: current_user,
            params: update_params,
            perform_spam_check: true).execute(issue)
        rescue QuickActions::InterpretService::QuickActionsNotAllowedError => error
          forbidden!(error.message)
        end

        if issue.valid?
          present issue, with: Entities::Issue, current_user: current_user, project: user_project
        else
          with_captcha_check_rest_api(spammable: issue) do
            render_validation_error!(issue)
          end
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Update the order of an issue' do
        detail 'Updates the order of a specified issue in a project. You can see the results when sorting issues ' \
          'manually.'
        success Entities::Issue
        tags ['projects']
      end
      params do
        requires :issue_iid, type: Integer, desc: 'Internal ID of the issue.'
        optional :move_after_id, type: Integer, desc: 'Global ID of the project issue to place this issue after.'
        optional :move_before_id, type: Integer, desc: 'Global ID of the project issue to place this issue before.'
        at_least_one_of :move_after_id, :move_before_id
      end
      route_setting :authorization, permissions: :reorder_issue, boundary_type: :project
      # rubocop: disable CodeReuse/ActiveRecord
      put ':id/issues/:issue_iid/reorder' do
        issue = user_project.issues.find_by(iid: params[:issue_iid])
        not_found!('Issue') unless issue

        authorize! :update_issue, issue

        if ::Issues::ReorderService.new(container: user_project, current_user: current_user, params: params).execute(issue)
          present issue, with: Entities::Issue, current_user: current_user, project: user_project
        else
          render_api_error!({ error: 'Unprocessable Entity' }, 422)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Move an issue' do
        detail 'Moves a specified issue to a different project. If the target project is the source project or the ' \
          'user has insufficient permissions, an error message with status code `400` is returned. If a label or ' \
          'milestone with the same name also exists in the target project, it is then assigned to the issue being ' \
          'moved.'
        success Entities::Issue
        tags ['projects']
      end
      params do
        requires :issue_iid, type: Integer, desc: 'Internal ID of the issue.'
        requires :to_project_id, type: Integer, desc: 'ID of the new project.'
      end
      route_setting :authorization, permissions: :move_issue, boundary_type: :project
      # rubocop: disable CodeReuse/ActiveRecord
      post ':id/issues/:issue_iid/move' do
        Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/20776', new_threshold: 260)

        issue = find_project_issue(params[:issue_iid])

        new_project = Project.find_by(id: params[:to_project_id])
        not_found!('Project') unless new_project

        begin
          response = ::WorkItems::DataSync::MoveService.new(
            work_item: issue, current_user: current_user, target_namespace: new_project.project_namespace
          ).execute

          render_api_error!(response.message, 400) if response.error?

          issue = response.payload[:work_item]

          present issue, with: Entities::Issue, current_user: current_user, project: new_project
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Clone an issue' do
        detail 'Clones a specified issue to a project. Copies as much data as possible as long as the target project ' \
          'contains equivalent criteria, such as labels or milestones. If you have insufficient permissions, an error ' \
          'message with status code `400` is returned.'
        success Entities::Issue
        tags ['projects']
      end
      params do
        requires :issue_iid, type: Integer, desc: 'Internal ID of the issue.'
        requires :to_project_id, type: Integer, desc: 'ID of the new project.'
        optional :with_notes, type: Boolean, desc: 'If `true`, clones the issue with its [notes](https://docs.gitlab.com/api/notes/).', default: false
      end
      route_setting :authorization, permissions: :clone_issue, boundary_type: :project
      # rubocop: disable CodeReuse/ActiveRecord
      post ':id/issues/:issue_iid/clone' do
        Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/340252')

        issue = find_project_issue(params[:issue_iid])

        target_project = Project.find_by(id: params[:to_project_id])
        not_found!('Project') unless target_project

        begin
          response = ::WorkItems::DataSync::CloneService.new(
            work_item: issue, current_user: current_user, target_namespace: target_project.project_namespace,
            params: { clone_with_notes: params[:with_notes] }
          ).execute

          render_api_error!(response.message, 400) if response.error?

          issue = response.payload[:work_item]

          present issue, with: Entities::Issue, current_user: current_user, project: target_project
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Delete an issue' do
        detail 'Deletes a specified issue.'
        success code: 204
        tags ['projects']
      end
      params do
        requires :issue_iid, type: Integer, desc: 'Internal ID of the issue.'
      end
      route_setting :authorization, permissions: :delete_issue, boundary_type: :project
      # rubocop: disable CodeReuse/ActiveRecord
      delete ":id/issues/:issue_iid" do
        issue = user_project.issues.find_by(iid: params[:issue_iid])
        not_found!('Issue') unless issue

        authorize!(:destroy_issue, issue)

        destroy_conditionally!(issue) do |issue|
          ::Issues::DestroyService.new(container: user_project, current_user: current_user).execute(issue)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'List all merge requests related to an issue' do
        detail 'Lists all merge requests that are related to a specified issue. If the project is private or the ' \
          'issue is confidential, you need to provide credentials to authorize. In most cases, you should ' \
          'authenticate with a personal access token.'
        success Entities::MergeRequestBasic
        tags ['issues']
      end
      params do
        requires :issue_iid, type: Integer, desc: 'Internal ID of the issue.'
      end
      route_setting :authorization, permissions: :read_issue_merge_request, boundary_type: :project
      get ':id/issues/:issue_iid/related_merge_requests' do
        issue = find_project_issue(params[:issue_iid])

        merge_requests = ::Issues::ReferencedMergeRequestsService
                           .new(container: user_project, current_user: current_user)
                           .related_merge_requests(issue)

        present paginate(::Kaminari.paginate_array(merge_requests)),
          with: Entities::MergeRequest,
          current_user: current_user,
          project: user_project,
          include_subscribed: false
      end

      desc 'List all merge requests that close an issue on merge' do
        detail 'Lists all merge requests that close a specified issue when merged. If the project is private or the ' \
          'issue is confidential, you need to provide credentials to authorize. In most cases, you should ' \
          'authenticate with a personal access token.'
        success Entities::MergeRequestBasic
        tags ['projects']
      end
      params do
        requires :issue_iid, type: Integer, desc: 'Internal ID of the issue.'
      end
      route_setting :authorization, permissions: :read_issue_closing_merge_request, boundary_type: :project
      # rubocop: disable CodeReuse/ActiveRecord
      get ':id/issues/:issue_iid/closed_by' do
        issue = find_project_issue(params[:issue_iid])

        merge_request_ids = MergeRequestIssue.link_type_closes.where(issue_id: issue).select(:merge_request_id)
        merge_requests = MergeRequestsFinder.new(current_user, project_id: user_project.id).execute.where(id: merge_request_ids)

        present paginate(merge_requests), with: Entities::MergeRequestBasic, current_user: current_user, project: user_project
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'List all participants in an issue' do
        detail 'Lists all users that are participants in a specified issue. If the project is private or the issue ' \
          'is confidential, you need to provide credentials to authorize. In most cases, you should authenticate ' \
          'with a personal access token.'
        success Entities::UserBasic
        tags ['issues']
      end
      params do
        requires :issue_iid, type: Integer, desc: 'Internal ID of the issue.'
      end
      route_setting :authorization, permissions: :read_issue_participant, boundary_type: :project
      get ':id/issues/:issue_iid/participants' do
        issue = find_project_issue(params[:issue_iid])
        participants = ::Kaminari.paginate_array(issue.participants(current_user))

        present paginate(participants), with: Entities::UserBasic, current_user: current_user, project: user_project
      end

      desc 'Retrieve user agent details for an issue' do
        detail 'Retrieves user agent details for an issue.'
        success Entities::UserAgentDetail
        tags ['issues']
      end
      params do
        requires :issue_iid, type: Integer, desc: 'Internal ID of the issue.'
      end
      route_setting :authorization, permissions: :read_issue_user_agent_detail, boundary_type: :project,
        assignable_when: [:admin]
      get ":id/issues/:issue_iid/user_agent_detail" do
        authenticated_as_admin!

        issue = find_project_issue(params[:issue_iid])

        break not_found!('UserAgentDetail') unless issue.user_agent_detail

        present issue.user_agent_detail, with: Entities::UserAgentDetail
      end
    end
  end
end

API::Issues.prepend_mod_with('API::Issues')
