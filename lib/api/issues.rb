module API
  # Issues API
  class Issues < Grape::API
    before { authenticate! }

    helpers do
      def filter_issues_state(issues, state)
        case state
        when 'opened' then issues.opened
        when 'closed' then issues.closed
        else issues
        end
      end

      def filter_issues_labels(issues, labels)
        issues.includes(:labels).where('labels.title' => labels.split(','))
      end

      def filter_issues_milestone(issues, milestone)
        issues.includes(:milestone).where('milestones.title' => milestone)
      end
    end

    resource :issues do
      # Get currently authenticated user's issues
      #
      # Parameters:
      #   state (optional) - Return "opened" or "closed" issues
      #   labels (optional) - Comma-separated list of label names
      #   order_by (optional) - Return requests ordered by `created_at` or `updated_at` fields. Default is `created_at`
      #   sort (optional) - Return requests sorted in `asc` or `desc` order. Default is `desc`
      #
      # Example Requests:
      #   GET /issues
      #   GET /issues?state=opened
      #   GET /issues?state=closed
      #   GET /issues?labels=foo
      #   GET /issues?labels=foo,bar
      #   GET /issues?labels=foo,bar&state=opened
      get do
        issues = current_user.issues.inc_notes_with_associations
        issues = filter_issues_state(issues, params[:state]) unless params[:state].nil?
        issues = filter_issues_labels(issues, params[:labels]) unless params[:labels].nil?
        issues.reorder(issuable_order_by => issuable_sort)
        present paginate(issues), with: Entities::Issue, current_user: current_user
      end
    end

    resource :groups do
      # Get a list of group issues
      #
      # Parameters:
      #   id (required) - The ID of a group
      #   state (optional) - Return "opened" or "closed" issues
      #   labels (optional) - Comma-separated list of label names
      #   milestone (optional) - Milestone title
      #   order_by (optional) - Return requests ordered by `created_at` or `updated_at` fields. Default is `created_at`
      #   sort (optional) - Return requests sorted in `asc` or `desc` order. Default is `desc`
      #
      # Example Requests:
      #   GET /groups/:id/issues
      #   GET /groups/:id/issues?state=opened
      #   GET /groups/:id/issues?state=closed
      #   GET /groups/:id/issues?labels=foo
      #   GET /groups/:id/issues?labels=foo,bar
      #   GET /groups/:id/issues?labels=foo,bar&state=opened
      #   GET /groups/:id/issues?milestone=1.0.0
      #   GET /groups/:id/issues?milestone=1.0.0&state=closed
      get ":id/issues" do
        group = find_group(params[:id])

        params[:state] ||= 'opened'
        params[:group_id] = group.id
        params[:milestone_title] = params.delete(:milestone)
        params[:label_name] = params.delete(:labels)
        params[:sort] = "#{params.delete(:order_by)}_#{params.delete(:sort)}" if params[:order_by] && params[:sort]

        issues = IssuesFinder.new(current_user, params).execute

        present paginate(issues), with: Entities::Issue, current_user: current_user
      end
    end

    resource :projects do
      # Get a list of project issues
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   iid (optional) - Return the project issue having the given `iid`
      #   state (optional) - Return "opened" or "closed" issues
      #   labels (optional) - Comma-separated list of label names
      #   milestone (optional) - Milestone title
      #   order_by (optional) - Return requests ordered by `created_at` or `updated_at` fields. Default is `created_at`
      #   sort (optional) - Return requests sorted in `asc` or `desc` order. Default is `desc`
      #
      # Example Requests:
      #   GET /projects/:id/issues
      #   GET /projects/:id/issues?state=opened
      #   GET /projects/:id/issues?state=closed
      #   GET /projects/:id/issues?labels=foo
      #   GET /projects/:id/issues?labels=foo,bar
      #   GET /projects/:id/issues?labels=foo,bar&state=opened
      #   GET /projects/:id/issues?milestone=1.0.0
      #   GET /projects/:id/issues?milestone=1.0.0&state=closed
      #   GET /issues?iid=42
      get ":id/issues" do
        issues = user_project.issues.inc_notes_with_associations.visible_to_user(current_user)
        issues = filter_issues_state(issues, params[:state]) unless params[:state].nil?
        issues = filter_issues_labels(issues, params[:labels]) unless params[:labels].nil?
        issues = filter_by_iid(issues, params[:iid]) unless params[:iid].nil?

        unless params[:milestone].nil?
          issues = filter_issues_milestone(issues, params[:milestone])
        end

        issues.reorder(issuable_order_by => issuable_sort)
        present paginate(issues), with: Entities::Issue, current_user: current_user
      end

      # Get a single project issue
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   issue_id (required) - The ID of a project issue
      # Example Request:
      #   GET /projects/:id/issues/:issue_id
      get ":id/issues/:issue_id" do
        @issue = find_project_issue(params[:issue_id])
        present @issue, with: Entities::Issue, current_user: current_user
      end

      # Create a new project issue
      #
      # Parameters:
      #   id (required)           - The ID of a project
      #   title (required)        - The title of an issue
      #   description (optional)  - The description of an issue
      #   assignee_id (optional)  - The ID of a user to assign issue
      #   milestone_id (optional) - The ID of a milestone to assign issue
      #   labels (optional)       - The labels of an issue
      #   created_at (optional)   - Date time string, ISO 8601 formatted
      #   due_date (optional)     - Date time string in the format YEAR-MONTH-DAY
      #   confidential (optional) - Boolean parameter if the issue should be confidential
      # Example Request:
      #   POST /projects/:id/issues
      post ':id/issues' do
        required_attributes! [:title]

        keys = [:title, :description, :assignee_id, :milestone_id, :due_date, :confidential]
        keys << :created_at if current_user.admin? || user_project.owner == current_user
        attrs = attributes_for_keys(keys)

        # Validate label names in advance
        if (errors = validate_label_params(params)).any?
          render_api_error!({ labels: errors }, 400)
        end

        attrs[:labels] = params[:labels] if params[:labels]

        # Convert and filter out invalid confidential flags
        attrs['confidential'] = to_boolean(attrs['confidential'])
        attrs.delete('confidential') if attrs['confidential'].nil?

        issue = ::Issues::CreateService.new(user_project, current_user, attrs.merge(request: request, api: true)).execute

        if issue.spam?
          render_api_error!({ error: 'Spam detected' }, 400)
        end

        if issue.valid?
          present issue, with: Entities::Issue, current_user: current_user
        else
          render_validation_error!(issue)
        end
      end

      # Update an existing issue
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   issue_id (required) - The ID of a project issue
      #   title (optional) - The title of an issue
      #   description (optional) - The description of an issue
      #   assignee_id (optional) - The ID of a user to assign issue
      #   milestone_id (optional) - The ID of a milestone to assign issue
      #   labels (optional) - The labels of an issue
      #   state_event (optional) - The state event of an issue (close|reopen)
      #   updated_at (optional) - Date time string, ISO 8601 formatted
      #   due_date (optional)     - Date time string in the format YEAR-MONTH-DAY
      #   confidential (optional) - Boolean parameter if the issue should be confidential
      # Example Request:
      #   PUT /projects/:id/issues/:issue_id
      put ':id/issues/:issue_id' do
        issue = user_project.issues.find(params[:issue_id])
        authorize! :update_issue, issue
        keys = [:title, :description, :assignee_id, :milestone_id, :state_event, :due_date, :confidential]
        keys << :updated_at if current_user.admin? || user_project.owner == current_user
        attrs = attributes_for_keys(keys)

        # Validate label names in advance
        if (errors = validate_label_params(params)).any?
          render_api_error!({ labels: errors }, 400)
        end

        attrs[:labels] = params[:labels] if params[:labels]

        # Convert and filter out invalid confidential flags
        attrs['confidential'] = to_boolean(attrs['confidential'])
        attrs.delete('confidential') if attrs['confidential'].nil?

        issue = ::Issues::UpdateService.new(user_project, current_user, attrs).execute(issue)

        if issue.valid?
          present issue, with: Entities::Issue, current_user: current_user
        else
          render_validation_error!(issue)
        end
      end

      # Move an existing issue
      #
      # Parameters:
      #  id (required)            - The ID of a project
      #  issue_id (required)      - The ID of a project issue
      #  to_project_id (required) - The ID of the new project
      # Example Request:
      #   POST /projects/:id/issues/:issue_id/move
      post ':id/issues/:issue_id/move' do
        required_attributes! [:to_project_id]

        issue = user_project.issues.find(params[:issue_id])
        new_project = Project.find(params[:to_project_id])

        begin
          issue = ::Issues::MoveService.new(user_project, current_user).execute(issue, new_project)
          present issue, with: Entities::Issue, current_user: current_user
        rescue ::Issues::MoveService::MoveError => error
          render_api_error!(error.message, 400)
        end
      end

      #
      # Delete a project issue
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   issue_id (required) - The ID of a project issue
      # Example Request:
      #   DELETE /projects/:id/issues/:issue_id
      delete ":id/issues/:issue_id" do
        issue = user_project.issues.find_by(id: params[:issue_id])

        authorize!(:destroy_issue, issue)
        issue.destroy
      end
    end
  end
end
