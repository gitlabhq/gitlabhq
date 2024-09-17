# frozen_string_literal: true

module Gitlab
  module HookData
    class ProjectMemberBuilder < BaseBuilder
      alias_method :project_member, :object

      # Sample data

      # {
      #   :created_at=>"2021-03-02T10:43:17Z",
      #   :updated_at=>"2021-03-02T10:43:17Z",
      #   :project_name=>"gitlab",
      #   :project_path=>"gitlab",
      #   :project_path_with_namespace=>"namespace1/gitlab",
      #   :project_id=>1,
      #   :user_username=>"johndoe",
      #   :user_name=>"John Doe",
      #   :user_email=>"john@example.com",
      #   :user_id=>2,
      #   :access_level=>"Developer",
      #   :project_visibility=>"internal",
      #   :event_name=>"user_update_for_team"
      #  }

      def build(event)
        [
          timestamps_data,
          project_member_data,
          event_data(event)
        ].reduce(:merge)
      end

      private

      def project_member_data
        project = project_member.project || Project.unscoped.find(project_member.source_id)

        {
          project_name: project.name,
          project_path: project.path,
          project_path_with_namespace: project.full_path,
          project_id: project.id,
          user_username: project_member.user.username,
          user_name: project_member.user.name,
          user_email: project_member.user.webhook_email,
          user_id: project_member.user.id,
          access_level: project_member.human_access,
          project_visibility: project.visibility
        }
      end

      def event_data(event)
        event_name =  case event
                      when :create
                        'user_add_to_team'
                      when :destroy
                        'user_remove_from_team'
                      when :update
                        'user_update_for_team'
                      when :request
                        'user_access_request_to_project'
                      when :revoke
                        'user_access_request_revoked_for_project'
                      end
        { event_name: event_name }
      end
    end
  end
end
