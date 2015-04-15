module API
  class GroupMembers < Grape::API
    before { authenticate! }

    resource :groups do
      # Get a list of group members viewable by the authenticated user.
      #
      # Example Request:
      #  GET /groups/:id/members
      get ":id/members" do
        group = find_group(params[:id])
        users = group.users
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
        group = find_group(params[:id])
        authorize! :admin_group, group
        required_attributes! [:user_id, :access_level]

        unless validate_access_level?(params[:access_level])
          render_api_error!("Wrong access level", 422)
        end

        if group.group_members.find_by(user_id: params[:user_id])
          render_api_error!("Already exists", 409)
        end

        group.add_users([params[:user_id]], params[:access_level], current_user)
        member = group.group_members.find_by(user_id: params[:user_id])
        present member.user, with: Entities::GroupMember, group: group
      end

      # Update group member
      #
      # Parameters:
      #   id (required) - The ID of a group
      #   user_id (required) - The ID of a group member
      #   access_level (required) - Project access level
      # Example Request:
      #   PUT /groups/:id/members/:user_id
      put ':id/members/:user_id' do
        group = find_group(params[:id])
        authorize! :admin_group, group
        required_attributes! [:access_level]

        group_member = group.group_members.find_by(user_id: params[:user_id])
        not_found!('User can not be found') if group_member.nil?

        if group_member.update_attributes(access_level: params[:access_level])
          @member = group_member.user
          present @member, with: Entities::GroupMember, group: group
        else
          handle_member_errors group_member.errors
        end
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
        authorize! :admin_group, group
        member = group.group_members.find_by(user_id: params[:user_id])

        if member.nil?
          render_api_error!("404 Not Found - user_id:#{params[:user_id]} not a member of group #{group.name}",404)
        else
          member.destroy
        end
      end
    end
  end
end
