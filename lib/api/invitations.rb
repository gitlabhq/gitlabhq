# frozen_string_literal: true

module API
  class Invitations < ::API::Base
    include PaginationParams

    feature_category :users

    before { authenticate! }

    helpers ::API::Helpers::MembersHelpers

    %w[group project].each do |source_type|
      params do
        requires :id, type: String, desc: "The #{source_type} ID"
      end
      resource source_type.pluralize, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc 'Invite non-members by email address to a group or project.' do
          detail 'This feature was introduced in GitLab 13.6'
          success Entities::Invitation
        end
        params do
          requires :email, types: [String, Array[String]], email_or_email_list: true, desc: 'The email address to invite, or multiple emails separated by comma'
          requires :access_level, type: Integer, values: Gitlab::Access.all_values, desc: 'A valid access level (defaults: `30`, developer access level)'
          optional :expires_at, type: DateTime, desc: 'Date string in the format YEAR-MONTH-DAY'
          optional :invite_source, type: String, desc: 'Source that triggered the member creation process', default: 'invitations-api'
        end
        post ":id/invitations" do
          params[:source] = find_source(source_type, params[:id])

          authorize_admin_source!(source_type, params[:source])

          ::Members::InviteService.new(current_user, params).execute
        end

        desc 'Get a list of group or project invitations viewable by the authenticated user' do
          detail 'This feature was introduced in GitLab 13.6'
          success Entities::Invitation
        end
        params do
          optional :query, type: String, desc: 'A query string to search for members'
          use :pagination
        end
        get ":id/invitations" do
          source = find_source(source_type, params[:id])
          query = params[:query]

          invitations = paginate(retrieve_member_invitations(source, query))

          present_member_invitations invitations
        end

        desc 'Updates a group or project invitation.' do
          success Entities::Member
        end
        params do
          requires :email, type: String, desc: 'The email address of the invitation.'
          optional :access_level, type: Integer, values: Gitlab::Access.all_values, desc: 'A valid access level (defaults: `30`, developer access level).'
          optional :expires_at, type: DateTime, desc: 'Date string in ISO 8601 format (`YYYY-MM-DDTHH:MM:SSZ`).'
        end
        put ":id/invitations/:email", requirements: { email: /[^\/]+/ } do
          source = find_source(source_type, params.delete(:id))
          invite_email = params[:email]
          authorize_admin_source!(source_type, source)

          invite = retrieve_member_invitations(source, invite_email).first
          not_found! unless invite

          update_params = declared_params(include_missing: false)
          update_params.delete(:email)
          bad_request! unless update_params.any?

          result = ::Members::UpdateService
            .new(current_user, update_params)
            .execute(invite)

          updated_member = result[:member]

          if result[:status] == :success
            present_members updated_member
          else
            render_validation_error!(updated_member)
          end
        end

        desc 'Removes an invitation from a group or project.'
        params do
          requires :email, type: String, desc: 'The email address of the invitation'
        end
        delete ":id/invitations/:email", requirements: { email: /[^\/]+/ } do
          source = find_source(source_type, params[:id])
          invite_email = params[:email]
          authorize_admin_source!(source_type, source)

          invite = retrieve_member_invitations(source, invite_email).first
          not_found! unless invite

          destroy_conditionally!(invite) do
            ::Members::DestroyService.new(current_user, params).execute(invite)
            unprocessable_entity! unless invite.destroyed?
          end
        end
      end
    end
  end
end
