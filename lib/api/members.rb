module API
  class Members < Grape::API
    before { authenticate! }

    helpers ::API::Helpers::MembersHelpers

    %w[group project].each do |source_type|
      resource source_type.pluralize do
        # Get a list of group/project members viewable by the authenticated user.
        #
        # Parameters:
        #   id (required) - The group/project ID
        #   query         - Query string
        #
        # Example Request:
        #   GET /groups/:id/members
        #   GET /projects/:id/members
        get ":id/members" do
          source = find_source(source_type, params[:id])

          members = source.members
          members = members.joins(:user).merge(User.search(params[:query])) if params[:query]
          users = Kaminari.paginate_array(members.map(&:user))

          present paginate(users), with: Entities::Member, source: source
        end

        # Get a group/project member
        #
        # Parameters:
        #   id (required) - The group/project ID
        #   user_id (required) - The user ID of the member
        #
        # Example Request:
        #   GET /groups/:id/members/:user_id
        #   GET /projects/:id/members/:user_id
        get ":id/members/:user_id" do
          source = find_source(source_type, params[:id])

          members = source.members
          member = members.find_by!(user_id: params[:user_id])

          present member.user, with: Entities::Member, member: member
        end

        # Add a new group/project member
        #
        # Parameters:
        #   id (required) - The group/project ID
        #   user_id (required) - The user ID of the new member
        #   access_level (required) - A valid access level
        #
        # Example Request:
        #   POST /groups/:id/members
        #   POST /projects/:id/members
        post ":id/members" do
          source = find_source(source_type, params[:id])
          authorize_admin_source!(source_type, source)
          required_attributes! [:user_id, :access_level]

          access_requester = source.requesters.find_by(user_id: params[:user_id])
          if access_requester
            # We pass current_user = access_requester so that the requester doesn't
            # receive a "access denied" email
            ::Members::DestroyService.new(access_requester, access_requester.user).execute
          end

          conflict!('Member already exists') if source.members.exists?(user_id: params[:user_id])

          source.add_user(params[:user_id], params[:access_level], current_user)
          member = source.members.find_by(user_id: params[:user_id])
          if member
            present member.user, with: Entities::Member, member: member
          else
            render_api_error!('400 Bad Request', 400)
          end
        end

        # Update a group/project member
        #
        # Parameters:
        #   id (required) - The group/project ID
        #   user_id (required) - The user ID of the member
        #   access_level (required) - A valid access level
        #
        # Example Request:
        #   PUT /groups/:id/members/:user_id
        #   PUT /projects/:id/members/:user_id
        put ":id/members/:user_id" do
          source = find_source(source_type, params[:id])
          authorize_admin_source!(source_type, source)
          required_attributes! [:user_id, :access_level]

          member = source.members.find_by!(user_id: params[:user_id])

          if member.update_attributes(access_level: params[:access_level])
            present member.user, with: Entities::Member, member: member
          else
            render_validation_error!(member)
          end
        end

        # Remove a group/project member
        #
        # Parameters:
        #   id (required) - The group/project ID
        #   user_id (required) - The user ID of the member
        #
        # Example Request:
        #   DELETE /groups/:id/members/:user_id
        #   DELETE /projects/:id/members/:user_id
        delete ":id/members/:user_id" do
          source = find_source(source_type, params[:id])
          required_attributes! [:user_id]

          member = source.members.find_by!(user_id: params[:user_id])

          ::Members::DestroyService.new(member, current_user).execute
          status :no_content
        end
      end
    end
  end
end
