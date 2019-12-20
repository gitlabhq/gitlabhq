# frozen_string_literal: true

# rubocop:disable GitlabSecurity/PublicSend

module API
  module Helpers
    module MembersHelpers
      def find_source(source_type, id)
        public_send("find_#{source_type}!", id) # rubocop:disable GitlabSecurity/PublicSend
      end

      def authorize_admin_source!(source_type, source)
        authorize! :"admin_#{source_type}", source
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def retrieve_members(source, params:, deep: false)
        members = deep ? find_all_members(source) : source.members.where.not(user_id: nil)
        members = members.includes(:user)
        members = members.references(:user).merge(User.search(params[:query])) if params[:query].present?
        members = members.where(user_id: params[:user_ids]) if params[:user_ids].present?
        members
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def find_all_members(source)
        members = source.is_a?(Project) ? find_all_members_for_project(source) : find_all_members_for_group(source)
        members.non_invite.non_request
      end

      def find_all_members_for_project(project)
        MembersFinder.new(project, current_user).execute(include_relations: [:inherited, :direct, :invited_groups_members])
      end

      def find_all_members_for_group(group)
        GroupMembersFinder.new(group).execute
      end

      def present_members(members)
        present members, with: Entities::Member, current_user: current_user
      end
    end
  end
end
