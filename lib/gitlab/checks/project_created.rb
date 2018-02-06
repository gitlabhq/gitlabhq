module Gitlab
  module Checks
    class ProjectCreated < PostPushMessage
      PROJECT_CREATED = "project_created".freeze

      def message
        <<~MESSAGE

        The private project #{project.full_path} was successfully created.

        To configure the remote, run:
          git remote add origin #{url_to_repo}

        To view the project, visit:
          #{project_url}

        MESSAGE
      end

      private

      def self.message_key(user_id, project_id)
        "#{PROJECT_CREATED}:#{user_id}:#{project_id}"
      end

      def project_url
        Gitlab::Routing.url_helpers.project_url(project)
      end
    end
  end
end
