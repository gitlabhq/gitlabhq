module API
  # groups API
  class Groups < Grape::API
    before { authenticate! }

    resource :groups do
      helpers do
        def find_group(id)
          group = Group.find(id)

          if can?(current_user, :read_group, group)
            group
          else
            render_api_error!("403 Forbidden - #{current_user.username} lacks sufficient access to #{group.name}", 403)
          end
        end

        def validate_access_level?(level)
          Gitlab::Access.options_with_owner.values.include? level.to_i
        end
      end

      # Get a groups list
      #
      # Example Request:
      #  GET /groups
      get do
        if current_user.admin
          @groups = paginate Group
        else
          @groups = paginate current_user.groups
        end
        present @groups, with: Entities::Group
      end

      # Create group. Available only for admin
      #
      # Parameters:
      #   name (required) - The name of the group
      #   path (required) - The path of the group
      # Example Request:
      #   POST /groups
      post do
        authenticated_as_admin!
        required_attributes! [:name, :path]

        attrs = attributes_for_keys [:name, :path]
        @group = Group.new(attrs)
        @group.owner = current_user

        if @group.save
          present @group, with: Entities::Group
        else
          not_found!
        end
      end

      # Get a single group, with containing projects
      #
      # Parameters:
      #   id (required) - The ID of a group
      # Example Request:
      #   GET /groups/:id
      get ":id" do
        group = find_group(params[:id])
        present group, with: Entities::GroupDetail
      end

      # Remove group
      #
      # Parameters:
      #   id (required) - The ID of a group
      # Example Request:
      #   DELETE /groups/:id
      delete ":id" do
        group = find_group(params[:id])
        authorize! :manage_group, group
        group.destroy
      end

      # Transfer a project to the Group namespace
      #
      # Parameters:
      #   id - group id
      #   project_id  - project id
      # Example Request:
      #   POST /groups/:id/projects/:project_id
      post ":id/projects/:project_id" do
        authenticated_as_admin!
        @group = Group.find(params[:id])
        project = Project.find(params[:project_id])
        if project.transfer(@group)
          present @group
        else
          not_found!
        end
      end

      # Get a list of group members viewable by the authenticated user.
      #
      # Example Request:
      #  GET /groups/:id/members
      get ":id/members" do
        group = find_group(params[:id])
        members = group.users_groups
        users = (paginate members).collect(&:user)
        present users, with: Entities::GroupMember, group: group
      end

      # Add a user to the list of group members
      #
      # Parameters:
      #   id (required) - group id
      #   user_id (required) - the users id
      #   access_level (required) - Project access level
      # Example Request:
      #  POST /groups/:id/members
      post ":id/members" do
        required_attributes! [:user_id, :access_level]
        unless validate_access_level?(params[:access_level])
          render_api_error!("Wrong access level", 422)
        end
        group = find_group(params[:id])
        if group.users_groups.find_by(user_id: params[:user_id])
          render_api_error!("Already exists", 409)
        end
        group.add_users([params[:user_id]], params[:access_level])
        member = group.users_groups.find_by(user_id: params[:user_id])
        present member.user, with: Entities::GroupMember, group: group
      end

      # Remove member.
      #
      # Parameters:
      #   id (required) - group id
      #   user_id (required) - the users id
      #
      # Example Request:
      #   DELETE /groups/:id/members/:user_id
      delete ":id/members/:user_id" do
        group = find_group(params[:id])
        member =  group.users_groups.find_by(user_id: params[:user_id])
        if member.nil?
          render_api_error!("404 Not Found - user_id:#{params[:user_id]} not a member of group #{group.name}",404)
        else
          member.destroy
        end
      end
    end
  end
end
