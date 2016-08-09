module API
  class AccessRequests < Grape::API
    before { authenticate! }

    helpers ::API::Helpers::MembersHelpers

    %w[group project].each do |source_type|
      resource source_type.pluralize do
        # Get a list of group/project access requests viewable by the authenticated user.
        #
        # Parameters:
        #   id (required) - The group/project ID
        #
        # Example Request:
        #  GET /groups/:id/access_requests
        #  GET /projects/:id/access_requests
        get ":id/access_requests" do
          source = find_source(source_type, params[:id])
          authorize_admin_source!(source_type, source)

          access_requesters = paginate(source.requesters.includes(:user))

          present access_requesters.map(&:user), with: Entities::AccessRequester, access_requesters: access_requesters
        end

        # Request access to the group/project
        #
        # Parameters:
        #   id (required) - The group/project ID
        #
        # Example Request:
        #  POST /groups/:id/access_requests
        #  POST /projects/:id/access_requests
        post ":id/access_requests" do
          source = find_source(source_type, params[:id])
          access_requester = source.request_access(current_user)

          if access_requester.persisted?
            present access_requester.user, with: Entities::AccessRequester, access_requester: access_requester
          else
            render_validation_error!(access_requester)
          end
        end

        # Approve a group/project access request
        #
        # Parameters:
        #   id (required) - The group/project ID
        #   user_id (required) - The user ID of the access requester
        #   access_level (optional) - Access level
        #
        # Example Request:
        #   PUT /groups/:id/access_requests/:user_id/approve
        #   PUT /projects/:id/access_requests/:user_id/approve
        put ':id/access_requests/:user_id/approve' do
          required_attributes! [:user_id]
          source = find_source(source_type, params[:id])
          authorize_admin_source!(source_type, source)

          member = source.requesters.find_by!(user_id: params[:user_id])
          if params[:access_level]
            member.update(access_level: params[:access_level])
          end
          member.accept_request

          status :created
          present member.user, with: Entities::Member, member: member
        end

        # Deny a group/project access request
        #
        # Parameters:
        #   id (required) - The group/project ID
        #   user_id (required) - The user ID of the access requester
        #
        # Example Request:
        #   DELETE /groups/:id/access_requests/:user_id
        #   DELETE /projects/:id/access_requests/:user_id
        delete ":id/access_requests/:user_id" do
          required_attributes! [:user_id]
          source = find_source(source_type, params[:id])

          access_requester = source.requesters.find_by!(user_id: params[:user_id])

          ::Members::DestroyService.new(access_requester, current_user).execute
        end
      end
    end
  end
end
