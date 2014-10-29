module API
  class GroupMembers < Grape::API
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

      # Get a list of group members viewable by the authenticated user.
      #
      # Example Request:
      #  GET /groups/:id/members
      get ":id/members" do
        group = find_group(params[:id])
        members = group.group_members
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
        group = find_group(params[:id])
        authorize! :manage_group, group
        required_attributes! [:user_id, :access_level]

        unless validate_access_level?(params[:access_level])
          render_api_error!("Wrong access level", 422)
        end

        if group.group_members.find_by(user_id: params[:user_id])
          render_api_error!("Already exists", 409)
        end

        group.add_users([params[:user_id]], params[:access_level])
        member = group.group_members.find_by(user_id: params[:user_id])
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
        authorize! :manage_group, group
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
