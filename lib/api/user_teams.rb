module API
  # user_teams API
  class UserTeams < Grape::API
    before { authenticate! }

    resource :user_teams do
      helpers do
        def handle_team_member_errors(errors)
          if errors[:permission].any?
            render_api_error!(errors[:permission], 422)
          end
          not_found!
        end

        def validate_access_level?(level)
          [UsersProject::GUEST, UsersProject::REPORTER, UsersProject::DEVELOPER, UsersProject::MASTER].include? level.to_i
        end
      end


      # Get a user_teams list
      #
      # Example Request:
      #  GET /user_teams
      get do
        if current_user.admin
          @user_teams = paginate UserTeam
        else
          @user_teams = paginate current_user.user_teams
        end
        present @user_teams, with: Entities::UserTeam
      end


      # Create user_team. Available only for admin
      #
      # Parameters:
      #   name (required) - The name of the user_team
      #   path (required) - The path of the user_team
      # Example Request:
      #   POST /user_teams
      post do
        authenticated_as_admin!
        required_attributes! [:name, :path]

        attrs = attributes_for_keys [:name, :path]
        @user_team = UserTeam.new(attrs)
        @user_team.owner = current_user

        if @user_team.save
          present @user_team, with: Entities::UserTeam
        else
          not_found!
        end
      end


      # Get a single user_team
      #
      # Parameters:
      #   id (required) - The ID of a user_team
      # Example Request:
      #   GET /user_teams/:id
      get ":id" do
        @user_team = UserTeam.find(params[:id])
        if current_user.admin or current_user.user_teams.include? @user_team
          present @user_team, with: Entities::UserTeam
        else
          not_found!
        end
      end


      # Get user_team members
      #
      # Parameters:
      #   id (required) - The ID of a user_team
      # Example Request:
      #   GET /user_teams/:id/members
      get ":id/members" do
        @user_team = UserTeam.find(params[:id])
        if current_user.admin or current_user.user_teams.include? @user_team
          @members = paginate @user_team.members
          present @members, with: Entities::TeamMember, user_team: @user_team
        else
          not_found!
        end
      end


      # Add a new user_team member
      #
      # Parameters:
      #   id (required) - The ID of a user_team
      #   user_id (required) - The ID of a user
      #   access_level (required) - Project access level
      # Example Request:
      #   POST /user_teams/:id/members
      post ":id/members" do
        authenticated_as_admin!
        required_attributes! [:user_id, :access_level]

        if not validate_access_level?(params[:access_level])
          render_api_error!("Wrong access level", 422)
        end

        @user_team = UserTeam.find(params[:id])
        if @user_team
          team_member = @user_team.user_team_user_relationships.find_by_user_id(params[:user_id])
          # Not existing member
          if team_member.nil?
            @user_team.add_member(params[:user_id], params[:access_level], false)
            team_member = @user_team.user_team_user_relationships.find_by_user_id(params[:user_id])

            if team_member.nil?
              render_api_error!("Error creating membership", 500)
            else
              @member = team_member.user
              present @member, with: Entities::TeamMember, user_team: @user_team
            end
          else
            render_api_error!("Already exists", 409)
          end
        else
          not_found!
        end
      end


      # Get a single team member from user_team
      #
      # Parameters:
      #   id (required) - The ID of a user_team
      #   user_id (required) - The ID of a team member
      # Example Request:
      #   GET /user_teams/:id/members/:user_id
      get ":id/members/:user_id" do
        @user_team = UserTeam.find(params[:id])
        if current_user.admin or current_user.user_teams.include? @user_team
          team_member = @user_team.user_team_user_relationships.find_by_user_id(params[:user_id])
          unless team_member.nil?
            present team_member.user, with: Entities::TeamMember, user_team: @user_team
          else
            not_found!
          end
        else
          not_found!
        end
      end

      # Remove a team member from user_team
      #
      # Parameters:
      #   id (required) - The ID of a user_team
      #   user_id (required) - The ID of a team member
      # Example Request:
      #   DELETE /user_teams/:id/members/:user_id
      delete ":id/members/:user_id" do
        authenticated_as_admin!

        @user_team = UserTeam.find(params[:id])
        if @user_team
          team_member = @user_team.user_team_user_relationships.find_by_user_id(params[:user_id])
          unless team_member.nil?
            team_member.destroy
          else
            not_found!
          end
        else
          not_found!
        end
      end


      # Get to user_team assigned projects
      #
      # Parameters:
      #   id (required) - The ID of a user_team
      # Example Request:
      #   GET /user_teams/:id/projects
      get ":id/projects" do
        @user_team = UserTeam.find(params[:id])
        if current_user.admin or current_user.user_teams.include? @user_team
          @projects = paginate @user_team.projects
          present @projects, with: Entities::TeamProject, user_team: @user_team
        else
          not_found!
        end
      end


      # Add a new user_team project
      #
      # Parameters:
      #   id (required) - The ID of a user_team
      #   project_id (required) - The ID of a project
      #   greatest_access_level (required) - Project access level
      # Example Request:
      #   POST /user_teams/:id/projects
      post ":id/projects" do
        authenticated_as_admin!
        required_attributes! [:project_id, :greatest_access_level]

        if not validate_access_level?(params[:greatest_access_level])
          render_api_error!("Wrong greatest_access_level", 422)
        end

        @user_team = UserTeam.find(params[:id])
        if @user_team
          team_project = @user_team.user_team_project_relationships.find_by_project_id(params[:project_id])

          # No existing project
          if team_project.nil?
            @user_team.assign_to_projects([params[:project_id]], params[:greatest_access_level])
            team_project = @user_team.user_team_project_relationships.find_by_project_id(params[:project_id])
            if team_project.nil?
              render_api_error!("Error creating project assignment", 500)
            else
              @project = team_project.project
              present @project, with: Entities::TeamProject, user_team: @user_team
            end
          else
            render_api_error!("Already exists", 409)
          end
        else
          not_found!
        end
      end

      # Show a single team project from user_team
      #
      # Parameters:
      #   id (required) - The ID of a user_team
      #   project_id (required) - The ID of a project assigned to the team
      # Example Request:
      #   GET /user_teams/:id/projects/:project_id
      get ":id/projects/:project_id" do
        @user_team = UserTeam.find(params[:id])
        if current_user.admin or current_user.user_teams.include? @user_team
          team_project = @user_team.user_team_project_relationships.find_by_project_id(params[:project_id])
          unless team_project.nil?
            present team_project.project, with: Entities::TeamProject, user_team: @user_team
          else
            not_found!
          end
        else
          not_found!
        end
      end

      # Remove a team project from user_team
      #
      # Parameters:
      #   id (required) - The ID of a user_team
      #   project_id (required) - The ID of a project assigned to the team
      # Example Request:
      #   DELETE /user_teams/:id/projects/:project_id
      delete ":id/projects/:project_id" do
        authenticated_as_admin!

        @user_team = UserTeam.find(params[:id])
        if @user_team
          team_project = @user_team.user_team_project_relationships.find_by_project_id(params[:project_id])
          unless team_project.nil?
            team_project.destroy
          else
            not_found!
          end
        else
          not_found!
        end
      end

    end
  end
end
