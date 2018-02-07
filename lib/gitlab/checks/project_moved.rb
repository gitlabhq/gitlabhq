module Gitlab
  module Checks
    class ProjectMoved < PostPushMessage
      REDIRECT_NAMESPACE = "redirect_namespace".freeze

      def initialize(project, user, protocol, redirected_path)
        @redirected_path = redirected_path

        super(project, user, protocol)
      end

      def message(rejected: false)
        <<~MESSAGE
        Project '#{redirected_path}' was moved to '#{project.full_path}'.

        Please update your Git remote:

          #{remote_url_message(rejected)}
        MESSAGE
      end

      def permanent_redirect?
        RedirectRoute.permanent.exists?(path: redirected_path)
      end

      private

      attr_reader :redirected_path

      def self.message_key(user_id, project_id)
        "#{REDIRECT_NAMESPACE}:#{user_id}:#{project_id}"
      end

      def remote_url_message(rejected)
        if rejected
          "git remote set-url origin #{url_to_repo} and try again."
        else
          "git remote set-url origin #{url_to_repo}"
        end
      end

      def url
        protocol == 'ssh' ? project.ssh_url_to_repo : project.http_url_to_repo
      end
    end
  end
end
