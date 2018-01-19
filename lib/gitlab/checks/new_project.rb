module Gitlab
  module Checks
    class NewProject
      NEW_PROJECT = "new_project".freeze

      def initialize(user, project, protocol)
        @user = user
        @project = project
        @protocol = protocol
      end

      def self.fetch_new_project_message(user_id, project_id)
        new_project_key = new_project_message_key(user_id, project_id)

        Gitlab::Redis::SharedState.with do |redis|
          message = redis.get(new_project_key)
          redis.del(new_project_key)
          message
        end
      end

      def add_new_project_message
        Gitlab::Redis::SharedState.with do |redis|
          key = self.class.new_project_message_key(user.id, project.id)
          redis.setex(key, 5.minutes, new_project_message)
        end
      end

      def new_project_message
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

      def self.new_project_message_key(user_id, project_id)
        "#{NEW_PROJECT}:#{user_id}:#{project_id}"
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
