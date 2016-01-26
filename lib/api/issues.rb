module API
  # Issues API
  class Issues < Grape::API
    before { authenticate! }

    helpers ::Gitlab::AkismetHelper

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

      def create_spam_log(project, current_user, attrs)
        params = attrs.merge({
          source_ip: env['REMOTE_ADDR'],
          user_agent: env['HTTP_USER_AGENT'],
          noteable_type: 'Issue',
          via_api: true
        })

        ::CreateSpamLogService.new(project, current_user, params).execute
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
        issues = current_user.issues
        issues = filter_issues_state(issues, params[:state]) unless params[:state].nil?
        issues = filter_issues_labels(issues, params[:labels]) unless params[:labels].nil?
        issues.reorder(issuable_order_by => issuable_sort)
        present paginate(issues), with: Entities::Issue
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
        issues = user_project.issues
        issues = filter_issues_state(issues, params[:state]) unless params[:state].nil?
        issues = filter_issues_labels(issues, params[:labels]) unless params[:labels].nil?
        issues = filter_by_iid(issues, params[:iid]) unless params[:iid].nil?

        unless params[:milestone].nil?
          issues = filter_issues_milestone(issues, params[:milestone])
        end

        issues.reorder(issuable_order_by => issuable_sort)
        present paginate(issues), with: Entities::Issue
      end

      # Get a single project issue
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   issue_id (required) - The ID of a project issue
      # Example Request:
      #   GET /projects/:id/issues/:issue_id
      get ":id/issues/:issue_id" do
        @issue = user_project.issues.find(params[:issue_id])
        present @issue, with: Entities::Issue
      end

      # Create a new project issue
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   title (required) - The title of an issue
      #   description (optional) - The description of an issue
      #   assignee_id (optional) - The ID of a user to assign issue
      #   milestone_id (optional) - The ID of a milestone to assign issue
      #   labels (optional) - The labels of an issue
      # Example Request:
      #   POST /projects/:id/issues
      post ":id/issues" do
        required_attributes! [:title]
        attrs = attributes_for_keys [:title, :description, :assignee_id, :milestone_id]

        # Validate label names in advance
        if (errors = validate_label_params(params)).any?
          render_api_error!({ labels: errors }, 400)
        end

        project = user_project
        text = [attrs[:title], attrs[:description]].reject(&:blank?).join("\n")

        if check_for_spam?(project, current_user) && is_spam?(env, current_user, text)
          create_spam_log(project, current_user, attrs)
          render_api_error!({ error: 'Spam detected' }, 400)
        end

        issue = ::Issues::CreateService.new(project, current_user, attrs).execute

        if issue.valid?
          # Find or create labels and attach to issue. Labels are valid because
          # we already checked its name, so there can't be an error here
          if params[:labels].present?
            issue.add_labels_by_names(params[:labels].split(','))
          end

          present issue, with: Entities::Issue
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
      # Example Request:
      #   PUT /projects/:id/issues/:issue_id
      put ":id/issues/:issue_id" do
        issue = user_project.issues.find(params[:issue_id])
        authorize! :update_issue, issue
        attrs = attributes_for_keys [:title, :description, :assignee_id, :milestone_id, :state_event]

        # Validate label names in advance
        if (errors = validate_label_params(params)).any?
          render_api_error!({ labels: errors }, 400)
        end

        issue = ::Issues::UpdateService.new(user_project, current_user, attrs).execute(issue)

        if issue.valid?
          # Find or create labels and attach to issue. Labels are valid because
          # we already checked its name, so there can't be an error here
          if params[:labels] && can?(current_user, :admin_issue, user_project)
            issue.remove_labels
            # Create and add labels to the new created issue
            issue.add_labels_by_names(params[:labels].split(','))
          end

          present issue, with: Entities::Issue
        else
          render_validation_error!(issue)
        end
      end

      # Delete a project issue (deprecated)
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   issue_id (required) - The ID of a project issue
      # Example Request:
      #   DELETE /projects/:id/issues/:issue_id
      delete ":id/issues/:issue_id" do
        not_allowed!
      end
    end
  end
end
