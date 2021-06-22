# frozen_string_literal: true

module Gitlab
  module Checks
    class ProjectCreated < PostPushMessage
      PROJECT_CREATED = "project_created"

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

      def self.message_key(user, repository)
        "#{PROJECT_CREATED}:#{user.id}:#{repository.gl_repository}"
      end

      # TODO: Remove in the next release
      # https://gitlab.com/gitlab-org/gitlab/-/issues/292030
      def self.legacy_message_key(user, repository)
        return unless repository.project

        "#{PROJECT_CREATED}:#{user.id}:#{repository.project.id}"
      end

      def project_url
        Gitlab::Routing.url_helpers.project_url(project)
      end
    end
  end
end
