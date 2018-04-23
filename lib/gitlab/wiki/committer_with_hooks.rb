module Gitlab
  module Wiki
    class CommitterWithHooks < Gollum::Committer
      attr_reader :gl_wiki

      def initialize(gl_wiki, options = {})
        @gl_wiki = gl_wiki
        super(gl_wiki.gollum_wiki, options)
      end

      def commit
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
