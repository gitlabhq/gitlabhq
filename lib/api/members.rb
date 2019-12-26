# frozen_string_literal: true

module API
  class Members < Grape::API
    include PaginationParams

    before { authenticate! }

    helpers ::API::Helpers::MembersHelpers

    %w[group project].each do |source_type|
      params do
        requires :id, type: String, desc: "The #{source_type} ID"
      end
      resource source_type.pluralize, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc 'Gets a list of group or project members viewable by the authenticated user.' do
          success Entities::Member
        end
        params do
          optional :query, type: String, desc: 'A query string to search for members'
          optional :user_ids, type: Array[Integer], desc: 'Array of user ids to look up for membership'
          use :optional_filter_params_ee
          use :pagination
        end

        get ":id/members" do
          source = find_source(source_type, params[:id])

          members = paginate(retrieve_members(source, params: params))

          present_members members
        end

        desc 'Gets a list of group or project members viewable by the authenticated user, including those who gained membership through ancestor group.' do
          success Entities::Member
        end
        params do
          optional :query, type: String, desc: 'A query string to search for members'
          optional :user_ids, type: Array[Integer], desc: 'Array of user ids to look up for membership'
          use :pagination
        end

        get ":id/members/all" do
          source = find_source(source_type, params[:id])

          members = paginate(retrieve_members(source, params: params, deep: true))

          present_members members
        end

        desc 'Gets a member of a group or project.' do
          success Entities::Member
        end
        params do
          requires :user_id, type: Integer, desc: 'The user ID of the member'
        end
        # rubocop: disable CodeReuse/ActiveRecord
        get ":id/members/:user_id" do
          source = find_source(source_type, params[:id])

          members = source.members
          member = members.find_by!(user_id: params[:user_id])

          present_members member
        end
        # rubocop: enable CodeReuse/ActiveRecord

        desc 'Gets a member of a group or project, including those who gained membership through ancestor group' do
          success Entities::Member
        end
        params do
          requires :user_id, type: Integer, desc: 'The user ID of the member'
        end
        # rubocop: disable CodeReuse/ActiveRecord
        get ":id/members/all/:user_id" do
          source = find_source(source_type, params[:id])

          members = find_all_members(source)
          member = members.find_by!(user_id: params[:user_id])

          present_members member
        end
        # rubocop: enable CodeReuse/ActiveRecord

        desc 'Adds a member to a group or project.' do
          success Entities::Member
        end
        params do
          requires :user_id, type: Integer, desc: 'The user ID of the new member'
          requires :access_level, type: Integer, desc: 'A valid access level (defaults: `30`, developer access level)'
          optional :expires_at, type: DateTime, desc: 'Date string in the format YEAR-MONTH-DAY'
        end
        # rubocop: disable CodeReuse/ActiveRecord
        post ":id/members" do
          source = find_source(source_type, params[:id])
          authorize_admin_source!(source_type, source)

          member = source.members.find_by(user_id: params[:user_id])
          conflict!('Member already exists') if member

          user = User.find_by_id(params[:user_id])
          not_found!('User') unless user

          member = source.add_user(user, params[:access_level], current_user: current_user, expires_at: params[:expires_at])

          if !member
            not_allowed! # This currently can only be reached in EE
          elsif member.persisted? && member.valid?
            present_members member
          else
            render_validation_error!(member)
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord

        desc 'Updates a member of a group or project.' do
          success Entities::Member
        end
        params do
          requires :user_id, type: Integer, desc: 'The user ID of the new member'
          requires :access_level, type: Integer, desc: 'A valid access level'
          optional :expires_at, type: DateTime, desc: 'Date string in the format YEAR-MONTH-DAY'
        end
        # rubocop: disable CodeReuse/ActiveRecord
        put ":id/members/:user_id" do
          source = find_source(source_type, params.delete(:id))
          authorize_admin_source!(source_type, source)

          member = source.members.find_by!(user_id: params[:user_id])
          updated_member =
            ::Members::UpdateService
              .new(current_user, declared_params(include_missing: false))
              .execute(member)

          if updated_member.valid?
            present_members updated_member
          else
            render_validation_error!(updated_member)
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord

        desc 'Removes a user from a group or project.'
        params do
          requires :user_id, type: Integer, desc: 'The user ID of the member'
        end
        # rubocop: disable CodeReuse/ActiveRecord
        delete ":id/members/:user_id" do
          source = find_source(source_type, params[:id])
          member = source.members.find_by!(user_id: params[:user_id])

          destroy_conditionally!(member) do
            ::Members::DestroyService.new(current_user).execute(member)
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
