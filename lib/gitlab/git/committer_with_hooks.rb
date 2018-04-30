module Gitlab
  module Git
    class CommitterWithHooks < Gollum::Committer
      attr_reader :gl_wiki

      def initialize(gl_wiki, options = {})
        @gl_wiki = gl_wiki
        super(gl_wiki.gollum_wiki, options)
      end

      def commit
        # TODO: Remove after 10.8
        return super unless allowed_to_run_hooks?

        result = Gitlab::Git::OperationService.new(git_user, gl_wiki.repository).with_branch(
          @wiki.ref,
          start_branch_name: @wiki.ref
        ) do |start_commit|
          super(false)
        end

        result[:newrev]
      rescue Gitlab::Git::HooksService::PreReceiveError => e
        message = "Custom Hook failed: #{e.message}"
        raise Gitlab::Git::Wiki::OperationError, message
      end

      private

      # TODO: Remove after 10.8
      def allowed_to_run_hooks?
        @options[:user_id] != 0 && @options[:username].present?
      end

      def git_user
        @git_user ||= Gitlab::Git::User.new(@options[:username],
                                            @options[:name],
                                            @options[:email],
                                            gitlab_id)
      end

      def gitlab_id
        Gitlab::GlId.gl_id_from_id_value(@options[:user_id])
      end
    end
  end
end
