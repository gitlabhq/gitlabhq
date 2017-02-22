module API
  class Issues < Grape::API
    include PaginationParams

    before { authenticate! }

    helpers do
      def find_issues(args = {})
        args = params.merge(args)

        args.delete(:id)
        args[:milestone_title] = args.delete(:milestone)

        match_all_labels = args.delete(:match_all_labels)
        labels = args.delete(:labels)
        args[:label_name] = labels if match_all_labels

        issues = IssuesFinder.new(current_user, args).execute.inc_notes_with_associations

        # TODO: Remove in 9.0  pass `label_name: args.delete(:labels)` to IssuesFinder
        if !match_all_labels && labels.present?
          issues = issues.includes(:labels).where('labels.title' => labels.split(','))
        end

        issues.reorder(args[:order_by] => args[:sort])
      end

      params :issues_params do
        optional :labels, type: String, desc: 'Comma-separated list of label names'
        optional :milestone, type: String, desc: 'Milestone title'
        optional :order_by, type: String, values: %w[created_at updated_at], default: 'created_at',
                            desc: 'Return issues ordered by `created_at` or `updated_at` fields.'
        optional :sort, type: String, values: %w[asc desc], default: 'desc',
                        desc: 'Return issues sorted in `asc` or `desc` order.'
        optional :milestone, type: String, desc: 'Return issues for a specific milestone'
        use :pagination
      end

      params :issue_params do
        optional :description, type: String, desc: 'The description of an issue'
        optional :assignee_id, type: Integer, desc: 'The ID of a user to assign issue'
        optional :milestone_id, type: Integer, desc: 'The ID of a milestone to assign issue'
        optional :labels, type: String, desc: 'Comma-separated list of label names'
        optional :due_date, type: String, desc: 'Date time string in the format YEAR-MONTH-DAY'
        optional :confidential, type: Boolean, desc: 'Boolean parameter if the issue should be confidential'
      end
    end

    resource :issues do
      desc "Get currently authenticated user's issues" do
        success Entities::Issue
      end
      params do
        optional :state, type: String, values: %w[opened closed all], default: 'all',
                         desc: 'Return opened, closed, or all issues'
        use :issues_params
      end
      get do
        issues = find_issues(scope: 'authored')

        present paginate(issues), with: Entities::Issue, current_user: current_user
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end
    resource :groups do
      desc 'Get a list of group issues' do
        success Entities::Issue
      end
      params do
        optional :state, type: String, values: %w[opened closed all], default: 'opened',
                         desc: 'Return opened, closed, or all issues'
        use :issues_params
      end
      get ":id/issues" do
        group = find_group!(params[:id])

        issues = find_issues(group_id: group.id, state: params[:state] || 'opened', match_all_labels: true)

        present paginate(issues), with: Entities::Issue, current_user: current_user
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects do
      include TimeTrackingEndpoints

      desc 'Get a list of project issues' do
        success Entities::Issue
      end
      params do
        optional :state, type: String, values: %w[opened closed all], default: 'all',
                         desc: 'Return opened, closed, or all issues'
        use :issues_params
      end
      get ":id/issues" do
        project = find_project(params[:id])

        issues = find_issues(project_id: project.id)

        present paginate(issues), with: Entities::Issue, current_user: current_user, project: user_project
      end

      desc 'Get a single project issue' do
        success Entities::Issue
      end
      params do
        requires :issue_id, type: Integer, desc: 'The ID of a project issue'
      end
      get ":id/issues/:issue_id" do
        issue = find_project_issue(params[:issue_id])
        present issue, with: Entities::Issue, current_user: current_user, project: user_project
      end

      desc 'Create a new project issue' do
        success Entities::Issue
      end
      params do
        requires :title, type: String, desc: 'The title of an issue'
        optional :created_at, type: DateTime,
                              desc: 'Date time when the issue was created. Available only for admins and project owners.'
        optional :merge_request_for_resolving_discussions, type: Integer,
                                                           desc: 'The IID of a merge request for which to resolve discussions'
        use :issue_params
      end
      post ':id/issues' do
        # Setting created_at time only allowed for admins and project owners
        unless current_user.admin? || user_project.owner == current_user
          params.delete(:created_at)
        end

        issue_params = declared_params(include_missing: false)

        if merge_request_iid = params[:merge_request_for_resolving_discussions]
          issue_params[:merge_request_for_resolving_discussions] = MergeRequestsFinder.new(current_user, project_id: user_project.id).
            execute.
            find_by(iid: merge_request_iid)
        end

        issue = ::Issues::CreateService.new(user_project,
                                            current_user,
                                            issue_params.merge(request: request, api: true)).execute
        if issue.spam?
          render_api_error!({ error: 'Spam detected' }, 400)
        end

        if issue.valid?
          present issue, with: Entities::Issue, current_user: current_user, project: user_project
        else
          render_validation_error!(issue)
        end
      end

      desc 'Update an existing issue' do
        success Entities::Issue
      end
      params do
        requires :issue_id, type: Integer, desc: 'The ID of a project issue'
        optional :title, type: String, desc: 'The title of an issue'
        optional :updated_at, type: DateTime,
                              desc: 'Date time when the issue was updated. Available only for admins and project owners.'
        optional :state_event, type: String, values: %w[reopen close], desc: 'State of the issue'
        use :issue_params
        at_least_one_of :title, :description, :assignee_id, :milestone_id,
                        :labels, :created_at, :due_date, :confidential, :state_event
      end
      put ':id/issues/:issue_id' do
        issue = user_project.issues.find(params.delete(:issue_id))
        authorize! :update_issue, issue

        # Setting created_at time only allowed for admins and project owners
        unless current_user.admin? || user_project.owner == current_user
          params.delete(:updated_at)
        end

        update_params = declared_params(include_missing: false).merge(request: request, api: true)

        issue = ::Issues::UpdateService.new(user_project,
                                            current_user,
                                            update_params).execute(issue)

        render_spam_error! if issue.spam?

        if issue.valid?
          present issue, with: Entities::Issue, current_user: current_user, project: user_project
        else
          render_validation_error!(issue)
        end
      end

      desc 'Move an existing issue' do
        success Entities::Issue
      end
      params do
        requires :issue_id, type: Integer, desc: 'The ID of a project issue'
        requires :to_project_id, type: Integer, desc: 'The ID of the new project'
      end
      post ':id/issues/:issue_id/move' do
        issue = user_project.issues.find_by(id: params[:issue_id])
        not_found!('Issue') unless issue

        new_project = Project.find_by(id: params[:to_project_id])
        not_found!('Project') unless new_project

        begin
          issue = ::Issues::MoveService.new(user_project, current_user).execute(issue, new_project)
          present issue, with: Entities::Issue, current_user: current_user, project: user_project
        rescue ::Issues::MoveService::MoveError => error
          render_api_error!(error.message, 400)
        end
      end

      desc 'Delete a project issue'
      params do
        requires :issue_id, type: Integer, desc: 'The ID of a project issue'
      end
      delete ":id/issues/:issue_id" do
        issue = user_project.issues.find_by(id: params[:issue_id])
        not_found!('Issue') unless issue

        authorize!(:destroy_issue, issue)
        issue.destroy
      end
    end
  end
end
