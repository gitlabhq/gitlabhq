module Gitlab
  module Checks
    class ProjectCreated
      PROJECT_CREATED = "project_created".freeze

      def initialize(user, project, protocol)
        @user = user
        @project = project
        @protocol = protocol
      end

      def self.fetch_project_created_message(user_id, project_id)
        project_created_key = project_created_message_key(user_id, project_id)

        Gitlab::Redis::SharedState.with do |redis|
          message = redis.get(project_created_key)
          redis.del(project_created_key)
          message
        end
      end

      def add_project_created_message
        return unless user.present? && project.present?

        Gitlab::Redis::SharedState.with do |redis|
          key = self.class.project_created_message_key(user.id, project.id)
          redis.setex(key, 5.minutes, project_created_message)
        end
      end

      def project_created_message
        <<~MESSAGE.strip_heredoc

        The private project #{project.full_path} was created.

        To configure the remote, run:
          git remote add origin #{git_url}

        To view the project, visit:
          #{project_url}

        MESSAGE
      end

      private

      attr_reader :project, :user, :protocol

      def self.project_created_message_key(user_id, project_id)
        "#{PROJECT_CREATED}:#{user_id}:#{project_id}"
      end

      def project_url
        Gitlab::Routing.url_helpers.project_url(project)
      end

      def git_url
        protocol == 'ssh' ? project.ssh_url_to_repo : project.http_url_to_repo
      end
    end
  end
end
