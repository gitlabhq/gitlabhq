# frozen_string_literal: true

module API
  class Issues < ::API::Base
    include PaginationParams
    helpers Helpers::IssuesHelpers
    helpers Helpers::RateLimiter

    before { authenticate_non_get! }

    feature_category :issue_tracking

    helpers do
      params :negatable_issue_filter_params do
        optional :labels, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce, desc: 'Comma-separated list of label names'
        optional :milestone, type: String, desc: 'Milestone title'
        optional :iids, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce, desc: 'The IID array of issues'

        optional :author_id, type: Integer, desc: 'Return issues which are not authored by the user with the given ID'
        optional :author_username, type: String, desc: 'Return issues which are not authored by the user with the given username'
        mutually_exclusive :author_id, :author_username

        optional :assignee_id, type: Integer, desc: 'Return issues which are not assigned to the user with the given ID'
        optional :assignee_username, type: Array[String], check_assignees_count: true,
                 coerce_with: Validations::Validators::CheckAssigneesCount.coerce,
                 desc: 'Return issues which are not assigned to the user with the given username'
        mutually_exclusive :assignee_id, :assignee_username

        use :negatable_issue_filter_params_ee
      end

      params :issues_stats_params do
        optional :labels, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce, desc: 'Comma-separated list of label names'
        optional :milestone, type: String, desc: 'Milestone title'
        optional :iids, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce, desc: 'The IID array of issues'
        optional :search, type: String, desc: 'Search issues for text present in the title, description, or any combination of these'
        optional :in, type: String, desc: '`title`, `description`, or a string joining them with comma'

        optional :author_id, type: Integer, desc: 'Return issues which are authored by the user with the given ID'
        optional :author_username, type: String, desc: 'Return issues which are authored by the user with the given username'
        mutually_exclusive :author_id, :author_username

        optional :assignee_id, types: [Integer, String], integer_none_any: true,
                 desc: 'Return issues which are assigned to the user with the given ID'
        optional :assignee_username, type: Array[String], check_assignees_count: true,
                 coerce_with: Validations::Validators::CheckAssigneesCount.coerce,
                 desc: 'Return issues which are assigned to the user with the given username'
        mutually_exclusive :assignee_id, :assignee_username

        optional :created_after, type: DateTime, desc: 'Return issues created after the specified time'
        optional :created_before, type: DateTime, desc: 'Return issues created before the specified time'
        optional :updated_after, type: DateTime, desc: 'Return issues updated after the specified time'
        optional :updated_before, type: DateTime, desc: 'Return issues updated before the specified time'

        optional :not, type: Hash do
          use :negatable_issue_filter_params
        end

        optional :scope, type: String, values: %w[created-by-me assigned-to-me created_by_me assigned_to_me all],
                         desc: 'Return issues for the given scope: `created_by_me`, `assigned_to_me` or `all`'
        optional :my_reaction_emoji, type: String, desc: 'Return issues reacted by the authenticated user by the given emoji'
        optional :confidential, type: Boolean, desc: 'Filter confidential or public issues'

        use :issues_stats_params_ee
      end

      params :issues_params do
        optional :with_labels_details, type: Boolean, desc: 'Return titles of labels and other details', default: false
        optional :state, type: String, values: %w[opened closed all], default: 'all',
                 desc: 'Return opened, closed, or all issues'
        optional :order_by, type: String, values: Helpers::IssuesHelpers.sort_options, default: 'created_at',
                 desc: 'Return issues ordered by `created_at` or `updated_at` fields.'
        optional :sort, type: String, values: %w[asc desc], default: 'desc',
                 desc: 'Return issues sorted in `asc` or `desc` order.'
        optional :due_date, type: String, values: %w[0 overdue week month next_month_and_previous_two_weeks] << '',
                 desc: 'Return issues that have no due date (`0`), or whose due date is this week, this month, between two weeks ago and next month, or which are overdue. Accepts: `overdue`, `week`, `month`, `next_month_and_previous_two_weeks`, `0`'
        optional :issue_type, type: String, values: Issue.issue_types.keys, desc: "The type of the issue. Accepts: #{Issue.issue_types.keys.join(', ')}"

        use :issues_stats_params
        use :pagination
      end

      params :issue_params do
        optional :description, type: String, desc: 'The description of an issue'
        optional :assignee_ids, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce, desc: 'The array of user IDs to assign issue'
        optional :assignee_id,  type: Integer, desc: '[Deprecated] The ID of a user to assign issue'
        optional :milestone_id, type: Integer, desc: 'The ID of a milestone to assign issue'
        optional :labels, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce, desc: 'Comma-separated list of label names'
        optional :add_labels, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce, desc: 'Comma-separated list of label names'
        optional :remove_labels, type: Array[String], coerce_with: ::API::Validations::Types::CommaSeparatedToArray.coerce, desc: 'Comma-separated list of label names'
        optional :due_date, type: String, desc: 'Date string in the format YEAR-MONTH-DAY'
        optional :confidential, type: Boolean, desc: 'Boolean parameter if the issue should be confidential'
        optional :discussion_locked, type: Boolean, desc: " Boolean parameter indicating if the issue's discussion is locked"
        optional :issue_type, type: String, values: Issue.issue_types.keys, desc: "The type of the issue. Accepts: #{Issue.issue_types.keys.join(', ')}"

        use :optional_issue_params_ee
      end
    end

    desc "Get currently authenticated user's issues statistics"
    params do
      use :issues_stats_params
      optional :scope, type: String, values: %w[created_by_me assigned_to_me all], default: 'created_by_me',
                       desc: 'Return issues for the given scope: `created_by_me`, `assigned_to_me` or `all`'
    end
    get '/issues_statistics' do
      authenticate! unless params[:scope] == 'all'

      present issues_statistics, with: Grape::Presenters::Presenter
    end

    resource :issues do
      desc "Get currently authenticated user's issues" do
        success Entities::Issue
      end
      params do
        use :issues_params
        optional :scope, type: String, values: %w[created-by-me assigned-to-me created_by_me assigned_to_me all], default: 'created_by_me',
                         desc: 'Return issues for the given scope: `created_by_me`, `assigned_to_me` or `all`'
        optional :non_archived, type: Boolean, default: true,
                                desc: 'Return issues from non archived projects'
      end
      get do
        authenticate! unless params[:scope] == 'all'
        issues = paginate(find_issues)

        options = {
          with: Entities::Issue,
          with_labels_details: declared_params[:with_labels_details],
          current_user: current_user,
          include_subscribed: false
        }

        present issues, options
      end

      desc "Get specified issue (admin only)" do
        success Entities::Issue
      end
      params do
        requires :id, type: String, desc: 'The ID of the Issue'
      end
      get ":id" do
        authenticated_as_admin!
        issue = Issue.find(params['id'])

        present issue, with: Entities::Issue, current_user: current_user, project: issue.project
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end
    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get a list of group issues' do
        success Entities::Issue
      end
      params do
        use :issues_params
        optional :non_archived, type: Boolean, desc: 'Return issues from non archived projects', default: true
      end
      get ":id/issues" do
        issues = paginate(find_issues(group_id: user_group.id, include_subgroups: true))

        options = {
          with: Entities::Issue,
          with_labels_details: declared_params[:with_labels_details],
          current_user: current_user,
          include_subscribed: false,
          group: user_group
        }

        present issues, options
      end

      desc 'Get statistics for the list of group issues'
      params do
        use :issues_stats_params
      end
      get ":id/issues_statistics" do
        present issues_statistics(group_id: user_group.id, include_subgroups: true), with: Grape::Presenters::Presenter
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      include TimeTrackingEndpoints

      desc 'Get a list of project issues' do
        success Entities::Issue
      end
      params do
        use :issues_params
      end
      get ":id/issues" do
        issues = paginate(find_issues(project_id: user_project.id))

        options = {
          with: Entities::Issue,
          with_labels_details: declared_params[:with_labels_details],
          current_user: current_user,
          project: user_project,
          include_subscribed: false
        }

        present issues, options
      end

      desc 'Get statistics for the list of project issues'
      params do
        use :issues_stats_params
      end
      get ":id/issues_statistics" do
        present issues_statistics(project_id: user_project.id), with: Grape::Presenters::Presenter
      end

      desc 'Get a single project issue' do
        success Entities::Issue
      end
      params do
        requires :issue_iid, type: Integer, desc: 'The internal ID of a project issue'
      end
      get ":id/issues/:issue_iid", as: :api_v4_project_issue do
        issue = find_project_issue(params[:issue_iid])
        present issue, with: Entities::Issue, current_user: current_user, project: user_project
      end

      desc 'Create a new project issue' do
        success Entities::Issue
      end
      params do
        requires :title, type: String, desc: 'The title of an issue'
        optional :created_at, type: DateTime,
                              desc: 'Date time when the issue was created. Available only for admins and project owners.'
        optional :merge_request_to_resolve_discussions_of, type: Integer,
                                                           desc: 'The IID of a merge request for which to resolve discussions'
        optional :discussion_to_resolve, type: String,
                                         desc: 'The ID of a discussion to resolve, also pass `merge_request_to_resolve_discussions_of`'
        optional :iid, type: Integer,
                       desc: 'The internal ID of a project issue. Available only for admins and project owners.'

        use :issue_params
      end
      post ':id/issues' do
        Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/21140')

        check_rate_limit! :issues_create, [current_user]

        authorize! :create_issue, user_project

        issue_params = declared_params(include_missing: false)

        issue_params = convert_parameters_from_legacy_format(issue_params)

        begin
          spam_params = ::Spam::SpamParams.new_from_request(request: request)
          issue = ::Issues::CreateService.new(project: user_project,
                                              current_user: current_user,
                                              params: issue_params,
                                              spam_params: spam_params).execute

          if issue.spam?
            render_api_error!({ error: 'Spam detected' }, 400)
          end

          if issue.valid?
            present issue, with: Entities::Issue, current_user: current_user, project: user_project
          else
            render_validation_error!(issue)
          end
        rescue ::ActiveRecord::RecordNotUnique
          render_api_error!('Duplicated issue', 409)
        end
      end

      desc 'Update an existing issue' do
        success Entities::Issue
      end
      params do
        requires :issue_iid, type: Integer, desc: 'The internal ID of a project issue'
        optional :title, type: String, desc: 'The title of an issue'
        optional :updated_at, type: DateTime,
                              allow_blank: false,
                              desc: 'Date time when the issue was updated. Available only for admins and project owners.'
        optional :state_event, type: String, values: %w[reopen close], desc: 'State of the issue'
        use :issue_params

        at_least_one_of(*Helpers::IssuesHelpers.update_params_at_least_one_of)
      end
      # rubocop: disable CodeReuse/ActiveRecord
      put ':id/issues/:issue_iid' do
        Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/20775')

        issue = user_project.issues.find_by!(iid: params.delete(:issue_iid))
        authorize! :update_issue, issue

        update_params = declared_params(include_missing: false)

        update_params = convert_parameters_from_legacy_format(update_params)

        spam_params = ::Spam::SpamParams.new_from_request(request: request)
        issue = ::Issues::UpdateService.new(project: user_project,
                                            current_user: current_user,
                                            params: update_params,
                                            spam_params: spam_params).execute(issue)

        render_spam_error! if issue.spam?

        if issue.valid?
          present issue, with: Entities::Issue, current_user: current_user, project: user_project
        else
          render_validation_error!(issue)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Reorder an existing issue' do
        success Entities::Issue
      end
      params do
        requires :issue_iid, type: Integer, desc: 'The internal ID of a project issue'
        optional :move_after_id, type: Integer, desc: 'The ID of the issue we want to be after'
        optional :move_before_id, type: Integer, desc: 'The ID of the issue we want to be before'
        at_least_one_of :move_after_id, :move_before_id
      end
      # rubocop: disable CodeReuse/ActiveRecord
      put ':id/issues/:issue_iid/reorder' do
        issue = user_project.issues.find_by(iid: params[:issue_iid])
        not_found!('Issue') unless issue

        authorize! :update_issue, issue

        if ::Issues::ReorderService.new(project: user_project, current_user: current_user, params: params).execute(issue)
          present issue, with: Entities::Issue, current_user: current_user, project: user_project
        else
          render_api_error!({ error: 'Unprocessable Entity' }, 422)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Move an existing issue' do
        success Entities::Issue
      end
      params do
        requires :issue_iid, type: Integer, desc: 'The internal ID of a project issue'
        requires :to_project_id, type: Integer, desc: 'The ID of the new project'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      post ':id/issues/:issue_iid/move' do
        Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/20776')

        issue = user_project.issues.find_by(iid: params[:issue_iid])
        not_found!('Issue') unless issue

        new_project = Project.find_by(id: params[:to_project_id])
        not_found!('Project') unless new_project

        begin
          issue = ::Issues::MoveService.new(project: user_project, current_user: current_user).execute(issue, new_project)
          present issue, with: Entities::Issue, current_user: current_user, project: user_project
        rescue ::Issues::MoveService::MoveError => error
          render_api_error!(error.message, 400)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'Delete a project issue'
      params do
        requires :issue_iid, type: Integer, desc: 'The internal ID of a project issue'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      delete ":id/issues/:issue_iid" do
        issue = user_project.issues.find_by(iid: params[:issue_iid])
        not_found!('Issue') unless issue

        authorize!(:destroy_issue, issue)

        destroy_conditionally!(issue) do |issue|
          Issuable::DestroyService.new(project: user_project, current_user: current_user).execute(issue)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'List merge requests that are related to the issue' do
        success Entities::MergeRequestBasic
      end
      params do
        requires :issue_iid, type: Integer, desc: 'The internal ID of a project issue'
      end
      get ':id/issues/:issue_iid/related_merge_requests' do
        issue = find_project_issue(params[:issue_iid])

        merge_requests = ::Issues::ReferencedMergeRequestsService.new(project: user_project, current_user: current_user)
          .execute(issue)
          .first

        present paginate(::Kaminari.paginate_array(merge_requests)),
          with: Entities::MergeRequest,
          current_user: current_user,
          project: user_project,
          include_subscribed: false
      end

      desc 'List merge requests closing issue' do
        success Entities::MergeRequestBasic
      end
      params do
        requires :issue_iid, type: Integer, desc: 'The internal ID of a project issue'
      end
      # rubocop: disable CodeReuse/ActiveRecord
      get ':id/issues/:issue_iid/closed_by' do
        issue = find_project_issue(params[:issue_iid])

        merge_request_ids = MergeRequestsClosingIssues.where(issue_id: issue).select(:merge_request_id)
        merge_requests = MergeRequestsFinder.new(current_user, project_id: user_project.id).execute.where(id: merge_request_ids)

        present paginate(merge_requests), with: Entities::MergeRequestBasic, current_user: current_user, project: user_project
      end
      # rubocop: enable CodeReuse/ActiveRecord

      desc 'List participants for an issue' do
        success Entities::UserBasic
      end
      params do
        requires :issue_iid, type: Integer, desc: 'The internal ID of a project issue'
      end
      get ':id/issues/:issue_iid/participants' do
        issue = find_project_issue(params[:issue_iid])
        participants = ::Kaminari.paginate_array(issue.participants)

        present paginate(participants), with: Entities::UserBasic, current_user: current_user, project: user_project
      end

      desc 'Get the user agent details for an issue' do
        success Entities::UserAgentDetail
      end
      params do
        requires :issue_iid, type: Integer, desc: 'The internal ID of a project issue'
      end
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
