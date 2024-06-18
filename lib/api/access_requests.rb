# frozen_string_literal: true

module API
  class AccessRequests < ::API::Base
    include PaginationParams

    before { authenticate! }

    helpers ::API::Helpers::MembersHelpers

    feature_category :system_access

    %w[group project].each do |source_type|
      params do
        requires :id, type: String,
          desc: "The ID or URL-encoded path of the #{source_type} owned by the authenticated user"
      end
      resource source_type.pluralize, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc "Gets a list of access requests for a #{source_type}." do
          detail 'This feature was introduced in GitLab 8.11.'
          success Entities::AccessRequester
          tags %w[access_requests]
        end
        params do
          use :pagination
        end
        # rubocop: disable CodeReuse/ActiveRecord
        get ":id/access_requests" do
          source = find_source(source_type, params[:id])

          access_requesters = AccessRequestsFinder.new(source).execute!(current_user)
          access_requesters = paginate(access_requesters.includes(:user))

          present access_requesters, with: Entities::AccessRequester
        end
        # rubocop: enable CodeReuse/ActiveRecord

        desc "Requests access for the authenticated user to a #{source_type}." do
          detail 'This feature was introduced in GitLab 8.11.'
          success Entities::AccessRequester
          success [
            {
              code: 200,
              model: Entities::AccessRequester,
              message: 'successful operation',
              examples: {
                successfull_response: {
                  "id" => 1,
                  "username" => "raymond_smith",
                  "name" => "Raymond Smith",
                  "state" => "active",
                  "created_at" => "2012-10-22T14:13:35Z",
                  "access_level" => 20
                }
              }
            }
          ]
          tags %w[access_requests]
        end
        post ":id/access_requests" do
          source = find_source(source_type, params[:id])
          access_requester = source.request_access(current_user)

          if access_requester.persisted?
            present access_requester, with: Entities::AccessRequester
          else
            render_validation_error!(access_requester)
          end
        end

        desc 'Approves an access request for the given user.' do
          detail 'This feature was introduced in GitLab 8.11.'
          success [
            {
              code: 200,
              model: Entities::AccessRequester,
              message: 'successful operation',
              examples: {
                successfull_response: {
                  "id" => 1,
                  "username" => "raymond_smith",
                  "name" => "Raymond Smith",
                  "state" => "active",
                  "created_at" => "2012-10-22T14:13:35Z",
                  "access_level" => 20
                }
              }
            }
          ]
          tags %w[access_requests]
        end
        params do
          requires :user_id, type: Integer, desc: 'The user ID of the access requester'
          optional :access_level, type: Integer, desc: 'A valid access level (defaults: `30`, the Developer role)',
            default: 30
        end
        # rubocop: disable CodeReuse/ActiveRecord
        put ':id/access_requests/:user_id/approve' do
          source = find_source(source_type, params[:id])

          access_requester = source.requesters.find_by!(user_id: params[:user_id])
          member = ::Members::ApproveAccessRequestService
            .new(current_user, declared_params)
            .execute(access_requester)

          status :created
          present member, with: Entities::Member
        end
        # rubocop: enable CodeReuse/ActiveRecord

        desc 'Denies an access request for the given user.' do
          detail 'This feature was introduced in GitLab 8.11.'
          tags %w[access_requests]
        end
        params do
          requires :user_id, type: Integer, desc: 'The user ID of the access requester'
        end
        # rubocop: disable CodeReuse/ActiveRecord
        delete ":id/access_requests/:user_id" do
          source = find_source(source_type, params[:id])
          member = source.requesters.find_by!(user_id: params[:user_id])

          destroy_conditionally!(member) do
            ::Members::DestroyService.new(current_user).execute(member)
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
