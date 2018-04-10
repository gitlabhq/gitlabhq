module Gitlab
  module Checks
    class ProjectMoved < PostPushMessage
      REDIRECT_NAMESPACE = "redirect_namespace".freeze

      def initialize(project, user, protocol, redirected_path)
        @redirected_path = redirected_path

        super(project, user, protocol)
      end

      def message
        <<~MESSAGE
        Project '#{redirected_path}' was moved to '#{project.full_path}'.

        Please update your Git remote:

          git remote set-url origin #{url_to_repo}
        MESSAGE
      end

      private

      attr_reader :redirected_path

      def self.message_key(user_id, project_id)
        "#{REDIRECT_NAMESPACE}:#{user_id}:#{project_id}"
      end
    end
  end
end
