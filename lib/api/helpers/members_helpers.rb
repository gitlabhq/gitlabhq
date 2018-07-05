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
        members = (source_type == 'project') ? find_all_members_for_project(source) : find_all_members_for_group(source)
        members.non_invite.
          non_request
      end

      def find_all_members_for_project(project)
        shared_group_ids = project.project_group_links.pluck(:group_id)
        source_ids = [project.id, project.group&.id].concat(shared_group_ids).compact
        Member.includes(:user).
          joins(user: :project_authorizations).
          where(project_authorizations: { project_id: project.id }).
          where(source_id: source_ids)
      end

      def find_all_members_for_group(group)
        source_ids = group.self_and_ancestors.pluck(:id)
        Member.includes(:user).
          where(source_id: source_ids).
          where(source_type: 'Namespace')
      end
    end
  end
end
