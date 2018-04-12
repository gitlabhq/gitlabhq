module Gitlab
  module Wiki
    class CommitterWithHooks < Gollum::Committer
      attr_reader :gl_wiki

      def initialize(gl_wiki, options = {})
        @gl_wiki = gl_wiki
        super(gl_wiki.gollum_wiki, options)
      end

      def commit(update_ref = true)
        Gitlab::Git::OperationService.new(git_user, gl_wiki.repository).with_branch(
          @wiki.ref,
          start_branch_name: @wiki.ref,
          start_repository: gl_wiki.repository
        ) do |start_commit|
          super(false)
        end
      rescue Gitlab::Git::HooksService::PreReceiveError
        msg = 'Failed to commit because of Pre-Received Hook'
        Rails.logger.error(msg)
        raise Gitlab::Git::Wiki::OperationError, msg
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

      def gl_repository
        gl_wiki.repository
      end
    end
  end
end
