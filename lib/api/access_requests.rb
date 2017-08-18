module API
  class AccessRequests < Grape::API
    include PaginationParams

    before { authenticate! }

    helpers ::API::Helpers::MembersHelpers

    %w[group project].each do |source_type|
      params do
        requires :id, type: String, desc: "The #{source_type} ID"
      end
      resource source_type.pluralize, requirements: { id: %r{[^/]+} } do
        desc "Gets a list of access requests for a #{source_type}." do
          detail 'This feature was introduced in GitLab 8.11.'
          success Entities::AccessRequester
        end
        params do
          use :pagination
        end
        get ":id/access_requests" do
          source = find_source(source_type, params[:id])

          access_requesters = AccessRequestsFinder.new(source).execute!(current_user)
          access_requesters = paginate(access_requesters.includes(:user))

          present access_requesters.map(&:user), with: Entities::AccessRequester, source: source
        end

        desc "Requests access for the authenticated user to a #{source_type}." do
          detail 'This feature was introduced in GitLab 8.11.'
          success Entities::AccessRequester
        end
        post ":id/access_requests" do
          source = find_source(source_type, params[:id])
          access_requester = source.request_access(current_user)

          if access_requester.persisted?
            present access_requester.user, with: Entities::AccessRequester, access_requester: access_requester
          else
            render_validation_error!(access_requester)
          end
        end

        desc 'Approves an access request for the given user.' do
          detail 'This feature was introduced in GitLab 8.11.'
          success Entities::Member
        end
        params do
          requires :user_id, type: Integer, desc: 'The user ID of the access requester'
          optional :access_level, type: Integer, desc: 'A valid access level (defaults: `30`, developer access level)'
        end
        put ':id/access_requests/:user_id/approve' do
          source = find_source(source_type, params[:id])

          member = ::Members::ApproveAccessRequestService.new(source, current_user, declared_params).execute

          status :created
          present member.user, with: Entities::Member, member: member
        end

        desc 'Denies an access request for the given user.' do
          detail 'This feature was introduced in GitLab 8.11.'
        end
        params do
          requires :user_id, type: Integer, desc: 'The user ID of the access requester'
        end
        delete ":id/access_requests/:user_id" do
          source = find_source(source_type, params[:id])

          status 204
          ::Members::DestroyService.new(source, current_user, params)
            .execute(:requesters)
        end
      end
    end
  end
end
