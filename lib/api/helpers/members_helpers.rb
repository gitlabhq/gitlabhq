# frozen_string_literal: true

module API
  module Helpers
    module MembersHelpers
      extend Grape::API::Helpers

      params :optional_filter_params_ee do
      end

      params :optional_state_filter_ee do
      end

      params :optional_put_params_ee do
      end

      def find_source(source_type, id)
        public_send("find_#{source_type}!", id) # rubocop:disable GitlabSecurity/PublicSend
      end

      def authorize_read_source_member!(source_type, source)
        authorize! :"read_#{source_type}_member", source
      end

      def authorize_admin_source_member!(source_type, source)
        authorize! :"admin_#{source_type}_member", source
      end

      def authorize_update_source_member!(source_type, member)
        authorize! :"update_#{source_type}_member", member
      end

      def authorize_admin_source!(source_type, source)
        authorize! :"admin_#{source_type}", source
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def retrieve_members(source, params:, deep: false)
        members = deep ? find_all_members(source) : source_members(source).connected_to_user
        members = members.allow_cross_joins_across_databases(url: "https://gitlab.com/gitlab-org/gitlab/-/issues/417456")
        members = members.includes(:user)
        members = members.references(:user).merge(User.search(params[:query], use_minimum_char_limit: false)) if params[:query].present?
        members = members.where(user_id: params[:user_ids]) if params[:user_ids].present?
        members
      end

      def retrieve_member_invitations(source, query = nil)
        members = source_members(source).where.not(invite_token: nil)
        members = members.includes(:user)
        members = members.where(invite_email: query) if query.present?
        members
      end

      def source_members(source)
        return source.namespace_members if source.is_a?(Project)

        source.members
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def find_all_members(source)
        members = source.is_a?(Project) ? find_all_members_for_project(source) : find_all_members_for_group(source)
        members.non_invite.non_request
      end

      def find_all_members_for_project(project)
        include_relations = [:inherited, :direct, :invited_groups, :shared_into_ancestors]
        MembersFinder.new(project, current_user).execute(include_relations: include_relations)
      end

      def find_all_members_for_group(group)
        GroupMembersFinder.new(group, current_user).execute(include_relations: [:inherited, :direct, :shared_from_groups])
      end

      def present_members(members)
        present members, with: Entities::Member, current_user: current_user, show_seat_info: params[:show_seat_info]
      end

      def present_member_invitations(invitations)
        present invitations, with: Entities::Invitation, current_user: current_user
      end

      def present_members_with_invited_private_group_accessibility(members, source)
        ::Members::InvitedPrivateGroupAccessibilityAssigner
          .new(members, source: source, current_user: current_user)
          .execute

        present_members members
      end

      def add_single_member(create_service_params)
        check_existing_membership(create_service_params)

        instance = ::Members::CreateService.new(current_user, create_service_params)
        result = instance.execute

        # This currently can only be reached in EE if group membership is locked
        not_allowed! if instance.membership_locked

        if result[:status] == :error && result[:http_status] == :unauthorized
          raise Gitlab::Access::AccessDeniedError
        end

        # prefer responding with model validations, if present
        member = instance.single_member
        render_validation_error!(member) if member&.invalid?

        present_add_single_member_response(result, member)
      end

      def present_put_membership_response(result)
        updated_member = result[:members].first

        if result[:status] == :success
          present_members updated_member
        else
          render_validation_error!(updated_member)
        end
      end

      def check_existing_membership(create_service_params)
        user_id = User.get_ids_by_ids_or_usernames(create_service_params[:user_id], create_service_params[:username]).first

        not_found!('User') unless user_id
        conflict!('Member already exists') if member_already_exists?(create_service_params[:source], user_id)
      end

      def add_multiple_members?(user_id, username)
        user_id&.include?(',') || username&.include?(',')
      end

      def self.member_access_levels
        Gitlab::Access.all_values
      end

      private

      def member_already_exists?(source, user_id)
        source.members.exists?(user_id: user_id) # rubocop: disable CodeReuse/ActiveRecord
      end

      def present_add_single_member_response(result, member)
        # if errors occurred besides model validations or authorization failures,
        # render those appropriately
        if result[:status] == :error
          render_structured_api_error!(result, :bad_request)
        else
          present_members(member)
        end
      end
    end
  end
end

API::Helpers::MembersHelpers.prepend_mod_with('API::Helpers::MembersHelpers')
