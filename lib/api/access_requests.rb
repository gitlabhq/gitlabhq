module API
  class AccessRequests < Grape::API
    before { authenticate! }

    helpers ::API::Helpers::MembersHelpers

    %w[group project].each do |source_type|
      params do
        requires :id, type: String, desc: 'The ID of the Group or Project'
      end
      resource source_type.pluralize do
        desc 'Get a list of group/project access requests viewable by the authenticated user' do
          detail 'This feature was introduced in GitLab 8.11'
          success Entities::AccessRequester
        end
        get ":id/access_requests" do
          source = find_source(source_type, params[:id])

          access_requesters = AccessRequestsFinder.new(source).execute!(current_user)
          access_requesters = paginate(access_requesters.includes(:user))

          present access_requesters.map(&:user), with: Entities::AccessRequester, source: source
        end

        desc 'Request access to the group/project' do
          detail 'This feature was introduced in GitLab 8.11'
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

        desc 'Approve a group/project access request' do
          detail 'This feature was introduced in GitLab 8.11'
          success Entities::Member
        end
        params do
          requires :user_id, type: Integer, desc: 'The user ID of the access requester'
          optional :access_level, type: Integer, desc: 'Access level'
        end
        put ':id/access_requests/:user_id/approve' do
          source = find_source(source_type, params[:id])

          member = ::Members::ApproveAccessRequestService.new(source, current_user, params).execute

          status :created
          present member.user, with: Entities::Member, member: member
        end

        desc 'Deny a group/project access request' do
          detail 'This feature was introduced in GitLab 8.11'
        end
        params do
          requires :user_id, type: Integer, desc: 'The user ID of the access requester'
        end
        delete ":id/access_requests/:user_id" do
          source = find_source(source_type, params[:id])

          access_requester = source.requesters.find_by!(user_id: params[:user_id])

          ::Members::DestroyService.new(access_requester, current_user).execute
        end
      end
    end
  end
end
