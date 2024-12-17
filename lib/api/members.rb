# frozen_string_literal: true

module API
  class Members < ::API::Base
    include PaginationParams

    before { authenticate! }

    urgency :low

    helpers ::API::Helpers::MembersHelpers

    {
      "group" => :groups_and_projects,
      "project" => :groups_and_projects
    }.each do |source_type, feature_category|
      params do
        requires :id, type: String, desc: "The #{source_type} ID"
      end
      resource source_type.pluralize, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc 'Gets a list of group or project members viewable by the authenticated user.' do
          success Entities::Member
          is_array true
          tags %w[members]
        end
        params do
          optional :query, type: String, desc: 'A query string to search for members'
          optional :user_ids, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce, desc: 'Array of user ids to look up for membership'
          optional :skip_users, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce, desc: 'Array of user ids to be skipped for membership'
          optional :show_seat_info, type: Boolean, desc: 'Show seat information for members'
          use :optional_filter_params_ee
          use :pagination
        end

        get ":id/members", feature_category: feature_category do
          source = find_source(source_type, params[:id])

          authorize_read_source_member!(source_type, source)

          members = paginate(retrieve_members(source, params: params))

          present_members members
        end

        desc 'Gets a list of group or project members viewable by the authenticated user, including those who gained membership through ancestor group.' do
          success Entities::Member
          is_array true
          tags %w[members]
        end
        params do
          optional :query, type: String, desc: 'A query string to search for members'
          optional :user_ids, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce, desc: 'Array of user ids to look up for membership'
          optional :show_seat_info, type: Boolean, desc: 'Show seat information for members'
          use :optional_state_filter_ee
          use :pagination
        end

        get ":id/members/all", feature_category: feature_category do
          source = find_source(source_type, params[:id])

          authorize_read_source_member!(source_type, source)

          members = paginate(retrieve_members(source, params: params, deep: true))

          present_members_with_invited_private_group_accessibility(members, source)
        end

        desc 'Gets a member of a group or project.' do
          success Entities::Member
          tags %w[members]
        end
        params do
          requires :user_id, type: Integer, desc: 'The user ID of the member'
        end
        # rubocop: disable CodeReuse/ActiveRecord
        get ":id/members/:user_id", feature_category: feature_category do
          source = find_source(source_type, params[:id])

          authorize_read_source_member!(source_type, source)

          members = source_members(source)
          member = members.find_by!(user_id: params[:user_id])

          present_members member
        end
        # rubocop: enable CodeReuse/ActiveRecord

        desc 'Gets a member of a group or project, including those who gained membership through ancestor group' do
          success Entities::Member
          tags %w[members]
        end
        params do
          requires :user_id, type: Integer, desc: 'The user ID of the member'
        end
        # rubocop: disable CodeReuse/ActiveRecord
        get ":id/members/all/:user_id", feature_category: feature_category do
          source = find_source(source_type, params[:id])

          authorize_read_source_member!(source_type, source)

          members = find_all_members(source).order(access_level: :desc)
          member = members.find_by!(user_id: params[:user_id])

          present_members_with_invited_private_group_accessibility(member, source)
        end
        # rubocop: enable CodeReuse/ActiveRecord

        desc 'Adds a member to a group or project.' do
          success Entities::Member
          tags %w[members]
        end
        params do
          requires :access_level, type: Integer, desc: 'A valid access level.'
          optional :user_id, types: [Integer, String], desc: 'The user ID of the new member or multiple IDs separated by commas.'
          optional :username, type: String, desc: 'The username of the new member or multiple usernames separated by commas.'
          optional :expires_at, type: DateTime, desc: 'Date string in the format YEAR-MONTH-DAY'
          optional :invite_source, type: String, desc: 'Source that triggered the member creation process', default: 'members-api'
          mutually_exclusive :user_id, :username
          at_least_one_of :user_id, :username
        end

        post ":id/members", feature_category: feature_category do
          source = find_source(source_type, params[:id])

          create_service_params = params.merge(source: source)

          if add_multiple_members?(params[:user_id].to_s, params[:username])
            ::Members::CreateService.new(current_user, create_service_params).execute
          else
            add_single_member(create_service_params)
          end
        end

        desc 'Updates a member of a group or project.' do
          success Entities::Member
          tags %w[members]
        end
        params do
          requires :user_id, type: Integer, desc: 'The user ID of the new member'
          requires :access_level, type: Integer, desc: 'A valid access level'
          optional :expires_at, type: DateTime, desc: 'Date string in the format YEAR-MONTH-DAY'
          use :optional_put_params_ee
        end
        # rubocop: disable CodeReuse/ActiveRecord
        put ":id/members/:user_id", feature_category: feature_category do
          source = find_source(source_type, params.delete(:id))
          member = source_members(source).find_by!(user_id: params[:user_id])

          authorize_update_source_member!(source_type, member)

          result = ::Members::UpdateService
            .new(current_user, declared_params(include_missing: false).merge({ source: source }))
            .execute(member)

          present_put_membership_response(result)
        end
        # rubocop: enable CodeReuse/ActiveRecord

        desc 'Removes a user from a group or project.' do
          tags %w[members]
        end
        params do
          requires :user_id, type: Integer, desc: 'The user ID of the member'
          optional :skip_subresources, type: Boolean, default: false,
            desc: 'Flag indicating if the deletion of direct memberships of the removed member in subgroups and projects should be skipped'
          optional :unassign_issuables, type: Boolean, default: false,
            desc: 'Flag indicating if the removed member should be unassigned from any issues or merge requests within given group or project'
        end
        # rubocop: disable CodeReuse/ActiveRecord
        delete ":id/members/:user_id", feature_category: feature_category do
          source = find_source(source_type, params[:id])
          member = source_members(source).find_by!(user_id: params[:user_id])

          check_rate_limit!(:members_delete, scope: [source, current_user])

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
