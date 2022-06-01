# frozen_string_literal: true

module API
  module Helpers
    module MembersHelpers
      extend Grape::API::Helpers

      params :optional_filter_params_ee do
      end

      params :optional_state_filter_ee do
      end

      def find_source(source_type, id)
        public_send("find_#{source_type}!", id) # rubocop:disable GitlabSecurity/PublicSend
      end

      def authorize_read_source_member!(source_type, source)
        authorize! :"read_#{source_type}_member", source
      end

      def authorize_admin_source!(source_type, source)
        authorize! :"admin_#{source_type}", source
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def retrieve_members(source, params:, deep: false)
        members = deep ? find_all_members(source) : source_members(source).connected_to_user
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
        source.members
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def find_all_members(source)
        members = source.is_a?(Project) ? find_all_members_for_project(source) : find_all_members_for_group(source)
        members.non_invite.non_request
      end

      def find_all_members_for_project(project)
        MembersFinder.new(project, current_user).execute(include_relations: [:inherited, :direct, :invited_groups])
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

      def add_single_member_by_user_id(create_service_params)
        source = create_service_params[:source]
        user_id = create_service_params[:user_ids]
        user = User.find_by(id: user_id) # rubocop: disable CodeReuse/ActiveRecord

        if user
          conflict!('Member already exists') if member_already_exists?(source, user_id)

          instance = ::Members::CreateService.new(current_user, create_service_params)
          instance.execute

          not_allowed! if instance.membership_locked # This currently can only be reached in EE if group membership is locked

          member = instance.single_member
          render_validation_error!(member) if member.invalid?

          present_members(member)
        else
          not_found!('User')
        end
      end

      def add_multiple_members?(user_id)
        user_id.include?(',')
      end

      def add_single_member?(user_id)
        user_id.present?
      end

      private

      def member_already_exists?(source, user_id)
        source.members.exists?(user_id: user_id) # rubocop: disable CodeReuse/ActiveRecord
      end
    end
  end
end

API::Helpers::MembersHelpers.prepend_mod_with('API::Helpers::MembersHelpers')
