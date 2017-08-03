module API
  class Members < Grape::API
    include PaginationParams

    before { authenticate! }

    helpers ::API::Helpers::MembersHelpers

    %w[group project].each do |source_type|
      params do
        requires :id, type: String, desc: "The #{source_type} ID"
      end
      resource source_type.pluralize, requirements: { id: %r{[^/]+} } do
        desc 'Gets a list of group or project members viewable by the authenticated user.' do
          success Entities::Member
        end
        params do
          optional :query, type: String, desc: 'A query string to search for members'
          use :pagination
        end
        get ":id/members" do
          source = find_source(source_type, params[:id])

          users = source.users
          users = users.merge(User.search(params[:query])) if params[:query]

          present paginate(users), with: Entities::Member, source: source
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

          present member.user, with: Entities::Member, member: member
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

          ## EE specific
          if source_type == 'project' && source.group && source.group.membership_lock
            not_allowed!
          end
          ## EE specific

          member = source.members.find_by(user_id: params[:user_id])
          conflict!('Member already exists') if member

          member = source.add_user(params[:user_id], params[:access_level], current_user: current_user, expires_at: params[:expires_at])

          if member.persisted? && member.valid?
            present member.user, with: Entities::Member, member: member
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

          member = source.members.find_by!(user_id: params.delete(:user_id))

          if member.update_attributes(declared_params(include_missing: false))
            present member.user, with: Entities::Member, member: member
          else
            render_validation_error!(member)
          end
        end

        desc 'Removes a user from a group or project.'
        params do
          requires :user_id, type: Integer, desc: 'The user ID of the member'
        end
        delete ":id/members/:user_id" do
          source = find_source(source_type, params[:id])
          # Ensure the member exists
          source.members.find_by!(user_id: params[:user_id])

          status 204
          ::Members::DestroyService.new(source, current_user, declared_params).execute
        end
      end
    end
  end
end
