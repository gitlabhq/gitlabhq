module API
  # Projects API
  class Projects < Grape::API
    before { authenticate! }

    resource :projects do
      helpers do
        def handle_project_member_errors(errors)
          if errors[:project_access].any?
            error!(errors[:project_access], 422)
          end
          not_found!
        end
      end

      # Get a projects list for authenticated user
      #
      # Example Request:
      #   GET /projects
      get do
        @projects = paginate current_user.authorized_projects
        present @projects, with: Entities::Project
      end

      # Get an owned projects list for authenticated user
      #
      # Example Request:
      #   GET /projects/owned
      get '/owned' do
        @projects = paginate current_user.owned_projects
        present @projects, with: Entities::Project
      end

      # Get a single project
      #
      # Parameters:
      #   id (required) - The ID of a project
      # Example Request:
      #   GET /projects/:id
      get ":id" do
        present user_project, with: Entities::Project
      end

      # Get a single project events
      #
      # Parameters:
      #   id (required) - The ID of a project
      # Example Request:
      #   GET /projects/:id
      get ":id/events" do
        limit = (params[:per_page] || 20).to_i
        offset = (params[:page] || 0).to_i * limit
        events = user_project.events.recent.limit(limit).offset(offset)

        present events, with: Entities::Event
      end

      # Create new project
      #
      # Parameters:
      #   name (required) - name for new project
      #   description (optional) - short project description
      #   default_branch (optional) - 'master' by default
      #   issues_enabled (optional)
      #   wall_enabled (optional)
      #   merge_requests_enabled (optional)
      #   wiki_enabled (optional)
      #   snippets_enabled (optional)
      #   namespace_id (optional) - defaults to user namespace
      #   public (optional) - false by default
      # Example Request
      #   POST /projects
      post do
        required_attributes! [:name]
        attrs = attributes_for_keys [:name,
                                    :path,
                                    :description,
                                    :default_branch,
                                    :issues_enabled,
                                    :wall_enabled,
                                    :merge_requests_enabled,
                                    :wiki_enabled,
                                    :snippets_enabled,
                                    :namespace_id,
                                    :public]
        @project = ::Projects::CreateContext.new(current_user, attrs).execute
        if @project.saved?
          present @project, with: Entities::Project
        else
          if @project.errors[:limit_reached].present?
            error!(@project.errors[:limit_reached], 403)
          end
          not_found!
        end
      end

      # Create new project for a specified user.  Only available to admin users.
      #
      # Parameters:
      #   user_id (required) - The ID of a user
      #   name (required) - name for new project
      #   description (optional) - short project description
      #   default_branch (optional) - 'master' by default
      #   issues_enabled (optional)
      #   wall_enabled (optional)
      #   merge_requests_enabled (optional)
      #   wiki_enabled (optional)
      #   snippets_enabled (optional)
      #   public (optional)
      # Example Request
      #   POST /projects/user/:user_id
      post "user/:user_id" do
        authenticated_as_admin!
        user = User.find(params[:user_id])
        attrs = attributes_for_keys [:name,
                                    :description,
                                    :default_branch,
                                    :issues_enabled,
                                    :wall_enabled,
                                    :merge_requests_enabled,
                                    :wiki_enabled,
                                    :snippets_enabled,
                                    :public]
        @project = ::Projects::CreateContext.new(user, attrs).execute
        if @project.saved?
          present @project, with: Entities::Project
        else
          not_found!
        end
      end


      # Mark this project as forked from another
      #
      # Parameters:
      #   id: (required) - The ID of the project being marked as a fork
      #   forked_from_id: (required) - The ID of the project it was forked from
      # Example Request:
      #   POST /projects/:id/fork/:forked_from_id
      post ":id/fork/:forked_from_id" do
        authenticated_as_admin!
        forked_from_project = find_project(params[:forked_from_id])
        unless forked_from_project.nil?
          if user_project.forked_from_project.nil?
            user_project.create_forked_project_link(forked_to_project_id: user_project.id, forked_from_project_id: forked_from_project.id)
          else
            render_api_error!("Project already forked", 409)
          end
        else
          not_found!
        end

      end

      # Remove a forked_from relationship
      #
      # Parameters:
      # id: (required) - The ID of the project being marked as a fork
      # Example Request:
      #  DELETE /projects/:id/fork
      delete ":id/fork" do
        authenticated_as_admin!
        unless user_project.forked_project_link.nil?
          user_project.forked_project_link.destroy
        end
      end


      # Get a project team members
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   query         - Query string
      # Example Request:
      #   GET /projects/:id/members
      get ":id/members" do
        if params[:query].present?
          @members = paginate user_project.users.where("username LIKE ?", "%#{params[:query]}%")
        else
          @members = paginate user_project.users
        end
        present @members, with: Entities::ProjectMember, project: user_project
      end

      # Get a project team members
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   user_id (required) - The ID of a user
      # Example Request:
      #   GET /projects/:id/members/:user_id
      get ":id/members/:user_id" do
        @member = user_project.users.find params[:user_id]
        present @member, with: Entities::ProjectMember, project: user_project
      end

      # Add a new project team member
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   user_id (required) - The ID of a user
      #   access_level (required) - Project access level
      # Example Request:
      #   POST /projects/:id/members
      post ":id/members" do
        authorize! :admin_project, user_project
        required_attributes! [:user_id, :access_level]

        # either the user is already a team member or a new one
        team_member = user_project.team_member_by_id(params[:user_id])
        if team_member.nil?
          team_member = user_project.users_projects.new(
            user_id: params[:user_id],
            project_access: params[:access_level]
          )
        end

        if team_member.save
          @member = team_member.user
          present @member, with: Entities::ProjectMember, project: user_project
        else
          handle_project_member_errors team_member.errors
        end
      end

      # Update project team member
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   user_id (required) - The ID of a team member
      #   access_level (required) - Project access level
      # Example Request:
      #   PUT /projects/:id/members/:user_id
      put ":id/members/:user_id" do
        authorize! :admin_project, user_project
        required_attributes! [:access_level]

        team_member = user_project.users_projects.find_by_user_id(params[:user_id])
        not_found!("User can not be found") if team_member.nil?

        if team_member.update_attributes(project_access: params[:access_level])
          @member = team_member.user
          present @member, with: Entities::ProjectMember, project: user_project
        else
          handle_project_member_errors team_member.errors
        end
      end

      # Remove a team member from project
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   user_id (required) - The ID of a team member
      # Example Request:
      #   DELETE /projects/:id/members/:user_id
      delete ":id/members/:user_id" do
        authorize! :admin_project, user_project
        team_member = user_project.users_projects.find_by_user_id(params[:user_id])
        unless team_member.nil?
          team_member.destroy
        else
          {message: "Access revoked", id: params[:user_id].to_i}
        end
      end
    end
  end
end
