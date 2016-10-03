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

          users = source.users
          users = users.merge(User.search(params[:query])) if params[:query]
          users = paginate(users)

          present users, with: Entities::Member, source: source
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
        #   expires_at (optional) - Date string in the format YEAR-MONTH-DAY
        #
        # Example Request:
        #   POST /groups/:id/members
        #   POST /projects/:id/members
        post ":id/members" do
          source = find_source(source_type, params[:id])
          authorize_admin_source!(source_type, source)
          required_attributes! [:user_id, :access_level]

          member = source.members.find_by(user_id: params[:user_id])

          # This is to ensure back-compatibility but 409 behavior should be used
          # for both project and group members in 9.0!
          conflict!('Member already exists') if source_type == 'group' && member

          unless member
            member = source.add_user(params[:user_id], params[:access_level], current_user: current_user, expires_at: params[:expires_at])
          end

          if member.persisted? && member.valid?
            present member.user, with: Entities::Member, member: member
          else
            # This is to ensure back-compatibility but 400 behavior should be used
            # for all validation errors in 9.0!
            render_api_error!('Access level is not known', 422) if member.errors.key?(:access_level)
            render_validation_error!(member)
          end
        end

        # Update a group/project member
        #
        # Parameters:
        #   id (required) - The group/project ID
        #   user_id (required) - The user ID of the member
        #   access_level (required) - A valid access level
        #   expires_at (optional) - Date string in the format YEAR-MONTH-DAY
        #
        # Example Request:
        #   PUT /groups/:id/members/:user_id
        #   PUT /projects/:id/members/:user_id
        put ":id/members/:user_id" do
          source = find_source(source_type, params[:id])
          authorize_admin_source!(source_type, source)
          required_attributes! [:user_id, :access_level]

          member = source.members.find_by!(user_id: params[:user_id])
          attrs = attributes_for_keys [:access_level, :expires_at]

          if member.update_attributes(attrs)
            present member.user, with: Entities::Member, member: member
          else
            # This is to ensure back-compatibility but 400 behavior should be used
            # for all validation errors in 9.0!
            render_api_error!('Access level is not known', 422) if member.errors.key?(:access_level)
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

          # This is to ensure back-compatibility but find_by! should be used
          # in that casse in 9.0!
          member = source.members.find_by(user_id: params[:user_id])

          # This is to ensure back-compatibility but this should be removed in
          # favor of find_by! in 9.0!
          not_found!("Member: user_id:#{params[:user_id]}") if source_type == 'group' && member.nil?

          # This is to ensure back-compatibility but 204 behavior should be used
          # for all DELETE endpoints in 9.0!
          if member.nil?
            { message: "Access revoked", id: params[:user_id].to_i }
          else
            ::Members::DestroyService.new(member, current_user).execute

            present member.user, with: Entities::Member, member: member
          end
        end
      end
    end
  end
end
