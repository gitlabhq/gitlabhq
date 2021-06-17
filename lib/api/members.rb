# frozen_string_literal: true

module API
  class Members < ::API::Base
    include PaginationParams

    before { authenticate! }

    feature_category :authentication_and_authorization

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
          optional :user_ids, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce, desc: 'Array of user ids to look up for membership'
          optional :show_seat_info, type: Boolean, desc: 'Show seat information for members'
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
          optional :user_ids, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce, desc: 'Array of user ids to look up for membership'
          optional :show_seat_info, type: Boolean, desc: 'Show seat information for members'
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

          members = source_members(source)
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
          requires :access_level, type: Integer, desc: 'A valid access level (defaults: `30`, developer access level)'
          requires :user_id, types: [Integer, String], desc: 'The user ID of the new member or multiple IDs separated by commas.'
          optional :expires_at, type: DateTime, desc: 'Date string in the format YEAR-MONTH-DAY'
          optional :invite_source, type: String, desc: 'Source that triggered the member creation process', default: 'members-api'
        end
        # rubocop: disable CodeReuse/ActiveRecord
        post ":id/members" do
          ::Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/333434')

          source = find_source(source_type, params[:id])
          authorize_admin_source!(source_type, source)

          if params[:user_id].to_s.include?(',')
            create_service_params = params.except(:user_id).merge({ user_ids: params[:user_id], source: source })

            ::Members::CreateService.new(current_user, create_service_params).execute
          elsif params[:user_id].present?
            member = source.members.find_by(user_id: params[:user_id])
            conflict!('Member already exists') if member

            user = User.find_by_id(params[:user_id])
            not_found!('User') unless user

            member = create_member(current_user, user, source, params)

            if !member
              not_allowed! # This currently can only be reached in EE
            elsif member.valid? && member.persisted?
              present_members(member)
              Gitlab::Tracking.event(::Members::CreateService.name, 'create_member', label: params[:invite_source], property: 'existing_user', user: current_user)
            else
              render_validation_error!(member)
            end
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

          member = source_members(source).find_by!(user_id: params[:user_id])

          result = ::Members::UpdateService
            .new(current_user, declared_params(include_missing: false))
            .execute(member)

          updated_member = result[:member]

          if result[:status] == :success
            present_members updated_member
          else
            render_validation_error!(updated_member)
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord

        desc 'Removes a user from a group or project.'
        params do
          requires :user_id, type: Integer, desc: 'The user ID of the member'
          optional :skip_subresources, type: Boolean, default: false,
                   desc: 'Flag indicating if the deletion of direct memberships of the removed member in subgroups and projects should be skipped'
          optional :unassign_issuables, type: Boolean, default: false,
                   desc: 'Flag indicating if the removed member should be unassigned from any issues or merge requests within given group or project'
        end
        # rubocop: disable CodeReuse/ActiveRecord
        delete ":id/members/:user_id" do
          source = find_source(source_type, params[:id])
          member = source_members(source).find_by!(user_id: params[:user_id])

          destroy_conditionally!(member) do
            ::Members::DestroyService.new(current_user).execute(member, skip_subresources: params[:skip_subresources], unassign_issuables: params[:unassign_issuables])
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end

API::Members.prepend_mod_with('API::Members')
