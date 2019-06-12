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

      def find_all_members(source_type, source)
        members = source_type == 'project' ? find_all_members_for_project(source) : find_all_members_for_group(source)
        members.non_invite
          .non_request
      end

      def find_all_members_for_project(project)
        MembersFinder.new(project, current_user).execute(include_invited_groups_members: true)
      end

      def find_all_members_for_group(group)
        GroupMembersFinder.new(group).execute
      end
    end
  end
end
