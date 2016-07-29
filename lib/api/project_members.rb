module API
  # Projects members API
  class ProjectMembers < Grape::API
    before { authenticate! }

    resource :projects do
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

        if user_project.group && user_project.group.membership_lock
          not_allowed!
        end

        # either the user is already a team member or a new one
        project_member = user_project.project_member(params[:user_id])
        if project_member.nil?
          project_member = user_project.project_members.new(
            user_id: params[:user_id],
            access_level: params[:access_level]
          )
        end

        if project_member.save
          @member = project_member.user
          present @member, with: Entities::ProjectMember, project: user_project
        else
          handle_member_errors project_member.errors
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

        project_member = user_project.project_members.find_by(user_id: params[:user_id])
        not_found!("User can not be found") if project_member.nil?

        if project_member.update_attributes(access_level: params[:access_level])
          @member = project_member.user
          present @member, with: Entities::ProjectMember, project: user_project
        else
          handle_member_errors project_member.errors
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
        project_member = user_project.project_members.find_by(user_id: params[:user_id])

        unless current_user.can?(:admin_project, user_project) ||
                current_user.can?(:destroy_project_member, project_member)
          forbidden!
        end

        if project_member.nil?
          { message: "Access revoked", id: params[:user_id].to_i }
        else
          project_member.destroy
        end
      end
    end
  end
end
