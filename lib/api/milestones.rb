module API
  # Milestones API
  class Milestones < Grape::API
    before { authenticate! }

    helpers do
      def filter_milestones_state(milestones, state)
        case state
        when 'active' then milestones.active
        when 'closed' then milestones.closed
        else milestones
        end
      end
    end

    resource :projects do
      # Get a list of project milestones
      #
      # Parameters:
      #   id (required)    - The ID of a project
      #   state (optional) - Return "active" or "closed" milestones
      # Example Request:
      #   GET /projects/:id/milestones
      #   GET /projects/:id/milestones?iid=42
      #   GET /projects/:id/milestones?state=active
      #   GET /projects/:id/milestones?state=closed
      get ":id/milestones" do
        authorize! :read_milestone, user_project

        milestones = user_project.milestones
        milestones = filter_milestones_state(milestones, params[:state])
        milestones = filter_by_iid(milestones, params[:iid]) if params[:iid].present?

        present paginate(milestones), with: Entities::Milestone
      end

      # Get a single project milestone
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   milestone_id (required) - The ID of a project milestone
      # Example Request:
      #   GET /projects/:id/milestones/:milestone_id
      get ":id/milestones/:milestone_id" do
        authorize! :read_milestone, user_project

        @milestone = user_project.milestones.find(params[:milestone_id])
        present @milestone, with: Entities::Milestone
      end

      # Create a new project milestone
      #
      # Parameters:
      #   id (required) - The ID of the project
      #   title (required) - The title of the milestone
      #   description (optional) - The description of the milestone
      #   due_date (optional) - The due date of the milestone
      # Example Request:
      #   POST /projects/:id/milestones
      post ":id/milestones" do
        authorize! :admin_milestone, user_project
        required_attributes! [:title]
        attrs = attributes_for_keys [:title, :description, :due_date]
        milestone = ::Milestones::CreateService.new(user_project, current_user, attrs).execute

        if milestone.valid?
          present milestone, with: Entities::Milestone
        else
          render_api_error!("Failed to create milestone #{milestone.errors.messages}", 400)
        end
      end

      # Update an existing project milestone
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   milestone_id (required) - The ID of a project milestone
      #   title (optional) - The title of a milestone
      #   description (optional) - The description of a milestone
      #   due_date (optional) - The due date of a milestone
      #   state_event (optional) - The state event of the milestone (close|activate)
      # Example Request:
      #   PUT /projects/:id/milestones/:milestone_id
      put ":id/milestones/:milestone_id" do
        authorize! :admin_milestone, user_project
        attrs = attributes_for_keys [:title, :description, :due_date, :state_event]
        milestone = user_project.milestones.find(params[:milestone_id])
        milestone = ::Milestones::UpdateService.new(user_project, current_user, attrs).execute(milestone)

        if milestone.valid?
          present milestone, with: Entities::Milestone
        else
          render_api_error!("Failed to update milestone #{milestone.errors.messages}", 400)
        end
      end

      # Get all issues for a single project milestone
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   milestone_id (required) - The ID of a project milestone
      # Example Request:
      #   GET /projects/:id/milestones/:milestone_id/issues
      get ":id/milestones/:milestone_id/issues" do
        authorize! :read_milestone, user_project

        @milestone = user_project.milestones.find(params[:milestone_id])

        finder_params = {
          project_id: user_project.id,
          milestone_title: @milestone.title,
          state: 'all'
        }

        issues = IssuesFinder.new(current_user, finder_params).execute
        present paginate(issues), with: Entities::Issue, current_user: current_user
      end
    end
  end
end
