module Gitlab
  module Wiki
    class CommitterWithHooks < Gollum::Committer
      def commit
        with_hooks do
          super
        end
      end

      private

      def git_user
        # TODO mirar lo de GLId
        @git_user ||= Gitlab::Git::User.new(@options[:username],
                                            @options[:name],
                                            @options[:email],
                                            gitlab_id)
      end

      def gitlab_id
        Gitlab::GlId.gl_id_from_id_value(@options[:id])
      end

      def with_hooks(&block)
        Gitlab::Git::HooksService.new.execute(
          git_user,
          @wiki.repo,
          Gitlab::Git::BLANK_SHA,
          '',
          Gitlab::Git::BRANCH_REF_PREFIX + @wiki.ref) do |service|

          yield(service)
        end
      end
    end
  end
end
