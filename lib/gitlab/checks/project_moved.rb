module Gitlab
  module Checks
    class ProjectMoved
      REDIRECT_NAMESPACE = "redirect_namespace".freeze

      def initialize(project, user, redirected_path, protocol)
        @project = project
        @user = user
        @redirected_path = redirected_path
        @protocol = protocol
      end

      def self.fetch_redirect_message(user_id, project_id)
        redirect_key = redirect_message_key(user_id, project_id)

        Gitlab::Redis::SharedState.with do |redis|
          message = redis.get(redirect_key)
          redis.del(redirect_key)
          message
        end
      end

      def add_redirect_message
        # Don't bother with sending a redirect message for anonymous clones
        # because they never see it via the `/internal/post_receive` endpoint
        return unless user.present? && project.present?

        Gitlab::Redis::SharedState.with do |redis|
          key = self.class.redirect_message_key(user.id, project.id)
          redis.setex(key, 5.minutes, redirect_message)
        end
      end

      def redirect_message(rejected: false)
        <<~MESSAGE.strip_heredoc
        Project '#{redirected_path}' was moved to '#{project.full_path}'.

        Please update your Git remote:

          #{remote_url_message(rejected)}
        MESSAGE
      end

      def permanent_redirect?
        RedirectRoute.permanent.exists?(path: redirected_path)
      end

      private

      attr_reader :project, :redirected_path, :protocol, :user

      def self.redirect_message_key(user_id, project_id)
        "#{REDIRECT_NAMESPACE}:#{user_id}:#{project_id}"
      end

      def remote_url_message(rejected)
        if rejected
          "git remote set-url origin #{url} and try again."
        else
          "git remote set-url origin #{url}"
        end
      end

      def url
        protocol == 'ssh' ? project.ssh_url_to_repo : project.http_url_to_repo
      end
    end
  end
end
