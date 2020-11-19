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
        end
        post ":id/invitations" do
          source = find_source(source_type, params[:id])

          authorize_admin_source!(source_type, source)

          ::Members::InviteService.new(current_user, params).execute(source)
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
      end
    end
  end
end
