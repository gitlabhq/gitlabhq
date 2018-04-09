module Gitlab
  module Wiki
    class CommitterWithHooks < Gollum::Committer
      attr_reader :gl_wiki

      def initialize(gl_wiki, options = {})
        @gl_wiki = gl_wiki
        super(gl_wiki.gollum_wiki, options)
      end

      def commit
        with_hooks do
          super
        end
      end

      private

      def with_hooks(&block)
        Gitlab::Git::HooksService.new.execute(
          git_user,
          gl_repository,
          wiki.repo.commits.first.id,
          Gitlab::Git::BLANK_SHA,
          Gitlab::Git::BRANCH_REF_PREFIX + @wiki.ref) do |service|
          yield(service)
        end
      rescue Gitlab::Git::HooksService::PreReceiveError
        msg = 'Failed to commit because of Pre-Received Hook'
        Rails.logger.error(msg)
        raise Gitlab::Git::Wiki::OperationError, msg
      end

      def git_user
        @git_user ||= Gitlab::Git::User.new(@options[:username],
                                            @options[:name],
                                            @options[:email],
                                            gitlab_id)
      end

      def gitlab_id
        Gitlab::GlId.gl_id_from_id_value(@options[:id])
      end

      def gl_repository
        gl_wiki.repository
      end
    end
  end
end
