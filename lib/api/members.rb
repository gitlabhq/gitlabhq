module API
  class Members < Grape::API
    include PaginationParams

    before { authenticate! }

    helpers ::API::Helpers::MembersHelpers

    %w[group project].each do |source_type|
      params do
        requires :id, type: String, desc: "The #{source_type} ID"
      end
      resource source_type.pluralize, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
        desc 'Gets a list of group or project members viewable by the authenticated user.' do
          success Entities::Member
        end
        params do
          optional :query, type: String, desc: 'A query string to search for members'
          use :pagination
        end
        get ":id/members" do
          source = find_source(source_type, params[:id])

          members = source.members.where.not(user_id: nil).includes(:user)
          members = members.joins(:user).merge(User.search(params[:query])) if params[:query].present?
          members = paginate(members)

          present members, with: Entities::Member
        end

        desc 'Gets a member of a group or project.' do
          success Entities::Member
        end
        params do
          requires :user_id, type: Integer, desc: 'The user ID of the member'
        end
        get ":id/members/:user_id" do
          source = find_source(source_type, params[:id])

          members = source.members
          member = members.find_by!(user_id: params[:user_id])

          present member, with: Entities::Member
        end

        desc 'Adds a member to a group or project.' do
          success Entities::Member
        end
        params do
          requires :user_id, type: Integer, desc: 'The user ID of the new member'
          requires :access_level, type: Integer, desc: 'A valid access level (defaults: `30`, developer access level)'
          optional :expires_at, type: DateTime, desc: 'Date string in the format YEAR-MONTH-DAY'
        end
        post ":id/members" do
          source = find_source(source_type, params[:id])
          authorize_admin_source!(source_type, source)

          member = source.members.find_by(user_id: params[:user_id])
          conflict!('Member already exists') if member

          member = source.add_user(params[:user_id], params[:access_level], current_user: current_user, expires_at: params[:expires_at])

          if !member
            not_allowed! # This currently can only be reached in EE
          elsif member.persisted? && member.valid?
            present member, with: Entities::Member
          else
            render_validation_error!(member)
          end
        end

        desc 'Updates a member of a group or project.' do
          success Entities::Member
        end
        params do
          requires :user_id, type: Integer, desc: 'The user ID of the new member'
          requires :access_level, type: Integer, desc: 'A valid access level'
          optional :expires_at, type: DateTime, desc: 'Date string in the format YEAR-MONTH-DAY'
        end
        put ":id/members/:user_id" do
          source = find_source(source_type, params.delete(:id))
          authorize_admin_source!(source_type, source)

          member = source.members.find_by!(user_id: params[:user_id])
          updated_member =
            ::Members::UpdateService
              .new(current_user, declared_params(include_missing: false))
              .execute(member)

          if updated_member.valid?
            present updated_member, with: Entities::Member
          else
            render_validation_error!(updated_member)
          end
        end

        desc 'Removes a user from a group or project.'
        params do
          requires :user_id, type: Integer, desc: 'The user ID of the member'
        end
        delete ":id/members/:user_id" do
          source = find_source(source_type, params[:id])
          member = source.members.find_by!(user_id: params[:user_id])

          destroy_conditionally!(member) do
            ::Members::DestroyService.new(current_user).execute(member)
          end
        end
      end
    end
  end
end
