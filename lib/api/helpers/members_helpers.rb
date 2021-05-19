# frozen_string_literal: true

module API
  module Helpers
    module MembersHelpers
      extend Grape::API::Helpers

      params :optional_filter_params_ee do
      end

      def find_source(source_type, id)
        public_send("find_#{source_type}!", id) # rubocop:disable GitlabSecurity/PublicSend
      end

      def authorize_admin_source!(source_type, source)
        authorize! :"admin_#{source_type}", source
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def retrieve_members(source, params:, deep: false)
        members = deep ? find_all_members(source) : source_members(source).connected_to_user
        members = members.includes(:user)
        members = members.references(:user).merge(User.search(params[:query])) if params[:query].present?
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
        GroupMembersFinder.new(group).execute
      end

      def create_member(current_user, user, source, params)
        source.add_user(user, params[:access_level], current_user: current_user, expires_at: params[:expires_at])
      end

      def present_members(members)
        present members, with: Entities::Member, current_user: current_user, show_seat_info: params[:show_seat_info]
      end

      def present_member_invitations(invitations)
        present invitations, with: Entities::Invitation, current_user: current_user
      end
    end
  end
end

API::Helpers::MembersHelpers.prepend_mod_with('API::Helpers::MembersHelpers')
