module API
  class Members < Grape::API
    before { authenticate! }

    helpers ::API::Helpers::MembersHelpers

    %w[group project].each do |source_type|
      params do
        requires :id, type: String, desc: "The #{source_type} ID"
      end
      resource source_type.pluralize do
        desc 'Gets a list of group or project members viewable by the authenticated user.' do
          success Entities::Member
        end
        params do
          optional :query, type: String, desc: 'A query string to search for members'
        end
        get ":id/members" do
          source = find_source(source_type, params[:id])

          users = source.users
          users = users.merge(User.search(params[:query])) if params[:query]
          users = paginate(users)

          present users, with: Entities::Member, source: source
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

          member = source.members.find_by(user_id: params[:user_id])

          # We need this explicit check because `source.add_user` doesn't
          # currently return the member created so it would return 201 even if
          # the member already existed...
          # The `source_type == 'group'` check is to ensure back-compatibility
          # but 409 behavior should be used for both project and group members in 9.0!
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

        desc 'Updates a member of a group or project.' do
          success Entities::Member
        end
        params do
          requires :user_id, type: Integer, desc: 'The user ID of the new member'
          requires :access_level, type: Integer, desc: 'A valid access level'
          optional :expires_at, type: DateTime, desc: 'Date string in the format YEAR-MONTH-DAY'
        end
        put ":id/members/:user_id" do
          source = find_source(source_type, params[:id])
          authorize_admin_source!(source_type, source)

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

        desc 'Removes a user from a group or project.'
        params do
          requires :user_id, type: Integer, desc: 'The user ID of the member'
        end
        delete ":id/members/:user_id" do
          source = find_source(source_type, params[:id])

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
            ::Members::DestroyService.new(source, current_user, declared(params)).execute

            present member.user, with: Entities::Member, member: member
          end
        end
      end
    end
  end
end
